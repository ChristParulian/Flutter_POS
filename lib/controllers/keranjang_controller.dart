import 'package:flutter/material.dart';
import '../models/keranjang.dart';

class KeranjangController with ChangeNotifier {
  final List<Keranjang> _keranjangList = [];

  List<Keranjang> get keranjangList => _keranjangList;

  void tambahKeKeranjang(Keranjang keranjang) {
    // Jika produk sudah ada dalam keranjang, tambahkan jumlahnya
    var index = _keranjangList.indexWhere((item) => item.id == keranjang.id);
    if (index != -1) {
      _keranjangList[index].tambahJumlah();
    } else {
      _keranjangList.add(keranjang);
    }
    notifyListeners();
  }

  // Jumlah produk tertentu yang sudah ada di keranjang, dipakai untuk validasi stok sebelum menambah
  int jumlahDiKeranjang(int produkId) {
    final index = _keranjangList.indexWhere((item) => item.id == produkId);
    return index == -1 ? 0 : _keranjangList[index].jumlah;
  }

  // Mengubah jumlah item tertentu langsung ke nilai baru (dipakai oleh stepper +/- di Checkout).
  // Tidak melakukan apa-apa kalau produknya tidak ada di keranjang, atau jumlah baru < 1
  // (penghapusan item harus lewat hapusDariKeranjang secara eksplisit, bukan lewat jumlah 0).
  void ubahJumlah(int produkId, int jumlahBaru) {
    if (jumlahBaru < 1) return;
    final index = _keranjangList.indexWhere((item) => item.id == produkId);
    if (index == -1) return;
    _keranjangList[index].jumlah = jumlahBaru;
    notifyListeners();
  }

  // Metode untuk menghapus item dari keranjang
  void hapusDariKeranjang(int idProduk) {
    _keranjangList.removeWhere((item) => item.id == idProduk);
    notifyListeners(); // Memberitahukan perubahan kepada listener
  }

  void kosongkanKeranjang() {
    _keranjangList.clear();
    notifyListeners();
  }

  double get totalHarga => _keranjangList.fold(0, (total, item) => total + item.totalHarga);
  int get totalItem => _keranjangList.fold(0, (count, item) => count + item.jumlah);
}
