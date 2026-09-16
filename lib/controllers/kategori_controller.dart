import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/kategori.dart';

class KategoriMasihDipakaiException implements Exception {
  final int jumlahProduk;
  KategoriMasihDipakaiException(this.jumlahProduk);

  @override
  String toString() => 'Kategori masih dipakai oleh $jumlahProduk produk';
}

class KategoriController extends ChangeNotifier {
  List<Kategori> _kategoriList = [];
  bool isLoading = true;

  // Mendapatkan daftar kategori dari database
  List<Kategori> get kategoriList => _kategoriList;

  // Menambah kategori ke dalam daftar dan database
  Future<void> addKategori(Kategori kategori) async {
    await DatabaseHelper.addKategori(kategori);
    await loadKategori(); // Update data setelah menambah kategori
  }

  // Menghapus kategori dari daftar dan database.
  // Melempar KategoriMasihDipakaiException jika masih ada produk yang memakai kategori ini,
  // supaya produk tidak menjadi yatim (kategoriId menggantung).
  Future<void> deleteKategori(int id) async {
    final jumlahProduk = await DatabaseHelper.countProdukByKategori(id);
    if (jumlahProduk > 0) {
      throw KategoriMasihDipakaiException(jumlahProduk);
    }
    await DatabaseHelper.deleteKategori(id);
    await loadKategori(); // Update data setelah menghapus kategori
  }

  // Mengupdate kategori dalam database
  Future<void> updateKategori(Kategori kategori) async {
    await DatabaseHelper.updateKategori(kategori);
    await loadKategori(); // Update data setelah mengupdate kategori
  }

  // Memuat ulang daftar kategori dari database
  Future<void> loadKategori() async {
    // Tidak memanggil notifyListeners() di sini: metode ini dipanggil langsung saat provider
    // dibuat (masih dalam proses build widget tree pertama), dan notify di titik itu memicu
    // "setState()/markNeedsBuild() called during build". Frame pertama sudah memakai nilai
    // awal isLoading=true, jadi notify baru diperlukan setelah data selesai dimuat (di bawah).
    isLoading = true;
    _kategoriList = await DatabaseHelper.getKategori();
    isLoading = false;
    notifyListeners();
  }
}
