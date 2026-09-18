import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kategori.dart';
import '../models/produk.dart';
import '../models/penjualan.dart';
import '../models/keranjang.dart';
import '../models/pengaturan.dart';

class StokTidakCukupException implements Exception {
  final String namaProduk;
  final int stokTersedia;
  StokTidakCukupException(this.namaProduk, this.stokTersedia);

  @override
  String toString() => 'Stok "$namaProduk" tidak cukup (tersisa $stokTersedia)';
}

class DatabaseHelper {
  static Database? _database;

  // Membuka koneksi ke database
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static _initDatabase() async {
    var path = await getDatabasesPath();
    var dbPath = join(path, 'kategori_produk.db');
    return await openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE produk ADD COLUMN stok INTEGER NOT NULL DEFAULT 0');
          await _createPenjualanTables(db);
          await _migrateOldPenjualanJson(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE produk ADD COLUMN barcode TEXT');
          await db.execute('ALTER TABLE produk ADD COLUMN fotoProduk TEXT');
          await _createBarcodeIndex(db);
        }
        if (oldVersion < 4) {
          await _createPengaturanTable(db);
        }
        if (oldVersion < 5) {
          // Pengaturan dibuat ulang di versi < 4, jadi kolom logoPath mungkin sudah ada
          // (tabel baru) atau belum (tabel v4). Cek dulu supaya ALTER tidak dobel.
          final cols = await db.rawQuery('PRAGMA table_info(pengaturan)');
          final punyaLogo = cols.any((c) => c['name'] == 'logoPath');
          if (!punyaLogo) {
            await db.execute('ALTER TABLE pengaturan ADD COLUMN logoPath TEXT');
          }
        }
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE kategori (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaKategori TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaProduk TEXT,
        harga REAL,
        kategoriId INTEGER,
        stok INTEGER NOT NULL DEFAULT 0,
        barcode TEXT,
        fotoProduk TEXT,
        FOREIGN KEY (kategoriId) REFERENCES kategori (id)
      )
    ''');
    await _createBarcodeIndex(db);

    await _createPenjualanTables(db);
    await _createPengaturanTable(db);
  }

  // Index unik untuk barcode. SQLite memperlakukan setiap NULL sebagai berbeda satu sama lain,
  // jadi banyak produk boleh tanpa barcode (NULL), tapi barcode yang sama tidak boleh dipakai
  // dua produk sekaligus. Barcode kosong dari form harus disimpan sebagai NULL, bukan string ''.
  static Future<void> _createBarcodeIndex(Database db) async {
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_produk_barcode ON produk (barcode)');
  }

  static Future<void> _createPenjualanTables(Database db) async {
    await db.execute('''
      CREATE TABLE penjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT,
        totalHarga REAL,
        jumlahDibayar REAL,
        kembalian REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE penjualan_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        penjualanId INTEGER,
        produkId INTEGER,
        namaProduk TEXT,
        harga REAL,
        jumlah INTEGER,
        FOREIGN KEY (penjualanId) REFERENCES penjualan (id)
      )
    ''');
  }

  // Tabel pengaturan menyimpan identitas toko (nama + alamat) sebagai satu baris dengan
  // id=1. Baris default langsung diisi supaya getPengaturan selalu punya hasil, berapapun
  // riwayat upgrade database-nya.
  static Future<void> _createPengaturanTable(Database db) async {
    await db.execute('''
      CREATE TABLE pengaturan (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        namaToko TEXT NOT NULL,
        alamatToko TEXT NOT NULL DEFAULT '',
        logoPath TEXT
      )
    ''');
    await db.insert('pengaturan', {
      'id': 1,
      'namaToko': 'Smart Toko',
      'alamatToko': '',
      'logoPath': null,
    });
  }

  // Migrasi satu kali data lama dari penjualan.json (versi sebelum SQLite) ke tabel penjualan
  static Future<void> _migrateOldPenjualanJson(Database db) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/penjualan.json');
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      for (final item in jsonList) {
        final penjualanId = await db.insert('penjualan', {
          'tanggal': item['tanggal'],
          'totalHarga': item['totalHarga'],
          'jumlahDibayar': item['jumlahDibayar'],
          'kembalian': item['kembalian'],
        });

        final List<dynamic> daftarProduk = item['daftarProduk'] ?? [];
        for (final produkItem in daftarProduk) {
          await db.insert('penjualan_item', {
            'penjualanId': penjualanId,
            'produkId': produkItem['id'],
            'namaProduk': produkItem['namaProduk'],
            'harga': produkItem['harga'],
            'jumlah': produkItem['jumlah'],
          });
        }
      }

      // Simpan sebagai cadangan, jangan dihapus, supaya tidak diimpor ulang tapi data lama tetap ada
      await file.rename('${directory.path}/penjualan.json.migrated');
    } catch (_) {
      // Jika file lama tidak ada, rusak, atau gagal dibaca: lewati migrasi tanpa menghentikan pembukaan database
    }
  }

  // ================= Kategori =================

  static Future<int> addKategori(Kategori kategori) async {
    final db = await database;
    return await db.insert('kategori', kategori.toMap());
  }

  static Future<int> deleteKategori(int id) async {
    final db = await database;
    return await db.delete('kategori', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Kategori>> getKategori() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kategori');
    return List.generate(maps.length, (i) {
      return Kategori.fromMap(maps[i]);
    });
  }

  static Future<int> updateKategori(Kategori kategori) async {
    final db = await database;
    return await db.update(
      'kategori',
      kategori.toMap(),
      where: 'id = ?',
      whereArgs: [kategori.id],
    );
  }

  // Menghitung jumlah produk yang masih memakai kategori ini, dipakai untuk mencegah kategori terpakai dihapus
  static Future<int> countProdukByKategori(int kategoriId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM produk WHERE kategoriId = ?',
      [kategoriId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ================= Produk =================

  static Future<int> addProduk(Produk produk) async {
    final db = await database;
    return await db.insert('produk', produk.toMap());
  }

  static Future<int> deleteProduk(int id) async {
    final db = await database;
    return await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Produk>> getProduk() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produk');
    return List.generate(maps.length, (i) {
      return Produk.fromMap(maps[i]);
    });
  }

  static Future<int> updateProduk(Produk produk) async {
    final db = await database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // Mencari produk berdasarkan barcode persis. Dipakai untuk validasi keunikan saat menyimpan produk.
  static Future<Produk?> getProdukByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query('produk',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (maps.isEmpty) return null;
    return Produk.fromMap(maps.first);
  }

  // ================= Penjualan =================

  // Menyimpan transaksi baru beserta item-itemnya dan mengurangi stok produk, semua dalam satu transaksi atomik.
  // Melempar StokTidakCukupException jika ada produk yang stoknya tidak cukup, dan seluruh transaksi dibatalkan.
  static Future<int> addPenjualan(Penjualan penjualan) async {
    final db = await database;
    return await db.transaction((txn) async {
      for (final item in penjualan.daftarProduk) {
        final rows = await txn.query('produk',
            columns: ['stok'], where: 'id = ?', whereArgs: [item.id]);
        final stokSaatIni =
            rows.isNotEmpty ? (rows.first['stok'] as int? ?? 0) : 0;
        if (stokSaatIni < item.jumlah) {
          throw StokTidakCukupException(item.namaProduk, stokSaatIni);
        }
      }

      final penjualanId = await txn.insert('penjualan', {
        'tanggal': penjualan.tanggal.toIso8601String(),
        'totalHarga': penjualan.totalHarga,
        'jumlahDibayar': penjualan.jumlahDibayar,
        'kembalian': penjualan.kembalian,
      });

      for (final item in penjualan.daftarProduk) {
        await txn.insert('penjualan_item', {
          'penjualanId': penjualanId,
          'produkId': item.id,
          'namaProduk': item.namaProduk,
          'harga': item.harga,
          'jumlah': item.jumlah,
        });
        await txn.rawUpdate(
          'UPDATE produk SET stok = stok - ? WHERE id = ?',
          [item.jumlah, item.id],
        );
      }

      return penjualanId;
    });
  }

  static Future<List<Penjualan>> getPenjualanList() async {
    final db = await database;
    final penjualanMaps = await db.query('penjualan', orderBy: 'tanggal DESC');

    final List<Penjualan> hasil = [];
    for (final map in penjualanMaps) {
      final itemMaps = await db.query(
        'penjualan_item',
        where: 'penjualanId = ?',
        whereArgs: [map['id']],
      );
      final daftarProduk = itemMaps
          .map((item) => Keranjang(
                id: item['produkId'] as int,
                namaProduk: item['namaProduk'] as String,
                harga: item['harga'] as double,
                jumlah: item['jumlah'] as int,
              ))
          .toList();
      hasil.add(Penjualan.fromMap(map, daftarProduk));
    }
    return hasil;
  }

  static Future<void> deletePenjualan(int id) async {
    final db = await database;
    await db
        .delete('penjualan_item', where: 'penjualanId = ?', whereArgs: [id]);
    await db.delete('penjualan', where: 'id = ?', whereArgs: [id]);
  }

  // ================= Pengaturan toko =================

  static Future<PengaturanToko?> getPengaturan() async {
    final db = await database;
    final maps = await db.query('pengaturan', where: 'id = 1', limit: 1);
    if (maps.isEmpty) return null;
    return PengaturanToko.fromMap(maps.first);
  }

  static Future<void> simpanPengaturan(PengaturanToko pengaturan) async {
    final db = await database;
    try {
      await db.insert(
        'pengaturan',
        {'id': 1, ...pengaturan.toMap()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('DatabaseHelper.simpanPengaturan error: $e');
      rethrow;
    }
  }
}
