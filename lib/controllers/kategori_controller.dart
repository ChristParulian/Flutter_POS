import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/kategori.dart';

class KategoriController extends ChangeNotifier {
  List<Kategori> _kategoriList = [];

  // Mendapatkan daftar kategori dari database
  List<Kategori> get kategoriList => _kategoriList;

  // Menambah kategori ke dalam daftar dan database
  Future<void> addKategori(Kategori kategori) async {
    await DatabaseHelper.addKategori(kategori);
    await loadKategori(); // Update data setelah menambah kategori
    notifyListeners();
  }

  // Menghapus kategori dari daftar dan database
  Future<void> deleteKategori(int id) async {
    await DatabaseHelper.deleteKategori(id);
    await loadKategori(); // Update data setelah menghapus kategori
    notifyListeners();
  }

  // Mengupdate kategori dalam database
  Future<void> updateKategori(Kategori kategori) async {
    await DatabaseHelper.updateKategori(kategori);
    await loadKategori(); // Update data setelah mengupdate kategori
    notifyListeners();
  }

  // Memuat ulang daftar kategori dari database
  Future<void> loadKategori() async {
    _kategoriList = await DatabaseHelper.getKategori();
    notifyListeners();
  }
}
