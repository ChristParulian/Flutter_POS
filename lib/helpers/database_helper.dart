import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kategori.dart';
import '../models/produk.dart';

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
    return await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
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
          FOREIGN KEY (kategoriId) REFERENCES kategori (id)
        )
      ''');
    });
  }

  // Fungsi untuk menambah kategori
  static Future<int> addKategori(Kategori kategori) async {
    final db = await database;
    return await db.insert('kategori', kategori.toMap());
  }

  // Fungsi untuk menghapus kategori
  static Future<int> deleteKategori(int id) async {
    final db = await database;
    return await db.delete('kategori', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk mendapatkan daftar kategori
  static Future<List<Kategori>> getKategori() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kategori');
    return List.generate(maps.length, (i) {
      return Kategori.fromMap(maps[i]);
    });
  }

  // Fungsi untuk mengupdate kategori
  static Future<int> updateKategori(Kategori kategori) async {
    final db = await database;
    return await db.update(
      'kategori',
      kategori.toMap(),
      where: 'id = ?',
      whereArgs: [kategori.id],
    );
  }

  // Fungsi untuk menambah produk
  static Future<int> addProduk(Produk produk) async {
    final db = await database;
    return await db.insert('produk', produk.toMap());
  }

  // Fungsi untuk menghapus produk
  static Future<int> deleteProduk(int id) async {
    final db = await database;
    return await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk mendapatkan daftar produk
  static Future<List<Produk>> getProduk() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produk');
    return List.generate(maps.length, (i) {
      return Produk.fromMap(maps[i]);
    });
  }

  // Fungsi untuk mengupdate produk
  static Future<int> updateProduk(Produk produk) async {
    final db = await database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }
}