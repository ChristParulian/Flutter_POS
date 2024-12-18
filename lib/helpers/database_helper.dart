import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kategori.dart';

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
    var dbPath = join(path, 'kategori.db');
    return await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE kategori (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          namaKategori TEXT
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
}
