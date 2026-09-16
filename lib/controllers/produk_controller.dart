import '../models/produk.dart';
import '../helpers/database_helper.dart';
import 'package:flutter/material.dart';

class ProdukTidakValidException implements Exception {
  final String pesan;
  ProdukTidakValidException(this.pesan);

  @override
  String toString() => pesan;
}

class ProdukController extends ChangeNotifier {
  List<Produk> _produkList = [];
  bool isLoading = true;

  List<Produk> get produkList => _produkList;

  // Memuat semua produk
  Future<void> loadProduk() async {
    // Tidak notifyListeners() sebelum await pertama: metode ini dipanggil langsung saat
    // provider dibuat (masih dalam proses build), lihat catatan yang sama di KategoriController.
    isLoading = true;
    _produkList = await DatabaseHelper.getProduk();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _validasi(Produk produk) async {
    if (produk.namaProduk.trim().isEmpty) {
      throw ProdukTidakValidException('Nama produk tidak boleh kosong');
    }
    if (produk.harga <= 0) {
      throw ProdukTidakValidException('Harga produk harus lebih dari 0');
    }
    if (produk.kategoriId <= 0) {
      throw ProdukTidakValidException('Kategori produk harus dipilih');
    }
    if (produk.stok < 0) {
      throw ProdukTidakValidException('Stok tidak boleh negatif');
    }
    final barcode = produk.barcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      final existing = await DatabaseHelper.getProdukByBarcode(barcode);
      if (existing != null && existing.id != produk.id) {
        throw ProdukTidakValidException('Barcode sudah dipakai produk lain');
      }
    }
  }

  // Menambahkan produk baru. Melempar ProdukTidakValidException jika data tidak valid.
  Future<void> addProduk(Produk produk) async {
    await _validasi(produk);
    await DatabaseHelper.addProduk(produk);
    await loadProduk();
  }

  // Menghapus produk
  Future<void> deleteProduk(int id) async {
    await DatabaseHelper.deleteProduk(id);
    await loadProduk();
  }

  // Mengupdate produk. Melempar ProdukTidakValidException jika data tidak valid.
  Future<void> updateProduk(Produk produk) async {
    if (produk.id == null || produk.id! <= 0) {
      throw ProdukTidakValidException('Produk tidak ditemukan');
    }
    await _validasi(produk);
    await DatabaseHelper.updateProduk(produk);
    await loadProduk();
  }
}
