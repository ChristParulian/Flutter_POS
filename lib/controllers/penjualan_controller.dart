import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/penjualan.dart';
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
    simpanPenjualanKeFile(); // Simpan ke file setelah penjualan ditambahkan
    notifyListeners(); // Memberitahu semua widget yang menggunakan controller ini
  }

  // Mendapatkan daftar penjualan
  List<Penjualan> get getPenjualan => daftarPenjualan;

  // Menyimpan daftar penjualan ke file JSON
  Future<void> simpanPenjualanKeFile() async {  // Mengubah menjadi public
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/penjualan.json');
    final jsonPenjualan = jsonEncode(daftarPenjualan.map((penjualan) => penjualan.toJson()).toList());
    await file.writeAsString(jsonPenjualan);
  }

  // Memuat daftar penjualan dari file JSON
  Future<void> muatPenjualanDariFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/penjualan.json');

    if (await file.exists()) {
      final fileContents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(fileContents);
      daftarPenjualan = jsonList.map((jsonItem) => Penjualan.fromJson(jsonItem)).toList();
      notifyListeners(); // Memberitahu bahwa data telah dimuat
    }
  }
}
