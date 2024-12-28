import 'package:flutter/material.dart';
import '../models/penjualan.dart'; // Pastikan model Penjualan sudah ada
import '../models/keranjang.dart'; // Pastikan model Keranjang sudah ada

class PenjualanController extends ChangeNotifier {
  List<Penjualan> daftarPenjualan = []; // Menyimpan daftar penjualan

  // Menyimpan penjualan baru
  void simpanPenjualan(List<Keranjang> keranjangList, double totalHarga, double jumlahDibayar, double kembalian) {
    final penjualan = Penjualan(
      tanggal: DateTime.now(),
      totalHarga: totalHarga,
      jumlahDibayar: jumlahDibayar,
      kembalian: kembalian,
      daftarProduk: List.from(keranjangList), // Salin data keranjang ke daftar produk
    );
    daftarPenjualan.add(penjualan); // Menambahkan penjualan baru ke daftar
    notifyListeners(); // Memberitahu semua widget yang menggunakan controller ini
  }

  // Mendapatkan daftar penjualan
  List<Penjualan> get getPenjualan => daftarPenjualan;
}
