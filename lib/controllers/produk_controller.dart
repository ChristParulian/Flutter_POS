import '../models/produk.dart';
import '../helpers/database_helper.dart';
import 'package:flutter/material.dart';

class ProdukController extends ChangeNotifier {
  List<Produk> _produkList = [];

  List<Produk> get produkList => _produkList;

  // Memuat semua produk
  Future<void> loadProduk() async {
    try {
      _produkList = await DatabaseHelper.getProduk();
      notifyListeners(); // Memberi tahu listener agar UI diupdate
    } catch (e) {
      print("Error loading produk: $e");
    }
  }

  // Menambahkan produk baru
  Future<void> addProduk(Produk produk) async {
    try {
      // Validasi input produk
      if (produk.namaProduk.isEmpty || produk.harga <= 0 || produk.kategoriId <= 0) {
        print("Produk tidak valid!");
        return; // Menghentikan eksekusi jika data tidak valid
      }

      await DatabaseHelper.addProduk(produk);
      await loadProduk(); // Memuat ulang produk setelah penambahan
      print("Produk berhasil ditambahkan.");
    } catch (e) {
      print("Error adding produk: $e");
    }
  }

  // Menghapus produk
  Future<void> deleteProduk(int id) async {
    try {
      await DatabaseHelper.deleteProduk(id);
      await loadProduk(); // Memuat ulang produk setelah penghapusan
      print("Produk berhasil dihapus.");
    } catch (e) {
      print("Error deleting produk: $e");
    }
  }

  // Mengupdate produk
  Future<void> updateProduk(Produk produk) async {
    try {
      // Validasi produk
      if (produk.id == null || produk.id! <= 0) {
        print("Produk tidak ditemukan!");
        return; // Menghentikan eksekusi jika ID produk tidak valid
      }
      if (produk.namaProduk.isEmpty || produk.harga <= 0 || produk.kategoriId <= 0) {
        print("Produk tidak valid!");
        return; // Menghentikan eksekusi jika data tidak valid
      }

      await DatabaseHelper.updateProduk(produk);
      await loadProduk(); // Memuat ulang produk setelah update
      print("Produk berhasil diperbarui.");
    } catch (e) {
      print("Error updating produk: $e");
    }
  }
}
