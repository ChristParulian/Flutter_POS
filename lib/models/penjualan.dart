import 'package:flutter/material.dart';
import 'keranjang.dart'; // Pastikan model Keranjang sudah ada

class Penjualan {
  final DateTime tanggal;
  final double totalHarga;
  final double jumlahDibayar;
  final double kembalian;
  final List<Keranjang> daftarProduk;

  Penjualan({
    required this.tanggal,
    required this.totalHarga,
    required this.jumlahDibayar,
    required this.kembalian,
    required this.daftarProduk,
  });

  String get formattedTanggal => '${tanggal.year}-${tanggal.month}-${tanggal.day}'; // Format tanggal
}
