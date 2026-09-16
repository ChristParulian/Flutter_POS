import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/penjualan.dart';
import '../models/keranjang.dart';

class PenjualanController extends ChangeNotifier {
  List<Penjualan> daftarPenjualan = [];
  bool isLoading = true;

  List<Penjualan> get getPenjualan => daftarPenjualan;

  // Menyimpan transaksi baru (menyimpan penjualan, item-itemnya, dan mengurangi stok, semua sekaligus).
  // Melempar StokTidakCukupException jika stok produk tidak lagi cukup saat checkout dilakukan.
  // Mengembalikan objek Penjualan yang baru tersimpan (lengkap dengan id dari database) supaya
  // bisa langsung dicetak struknya tanpa perlu query ulang atau menebak ulang waktu transaksi.
  Future<Penjualan> simpanPenjualan(
    List<Keranjang> keranjangList,
    double totalHarga,
    double jumlahDibayar,
    double kembalian,
  ) async {
    final penjualan = Penjualan(
      tanggal: DateTime.now(),
      totalHarga: totalHarga,
      jumlahDibayar: jumlahDibayar,
      kembalian: kembalian,
      daftarProduk: List.from(keranjangList),
    );
    penjualan.id = await DatabaseHelper.addPenjualan(penjualan);
    await muatPenjualan();
    return penjualan;
  }

  // Menghapus penjualan dari daftar dan database
  Future<void> hapusPenjualan(Penjualan penjualan) async {
    if (penjualan.id == null) return;
    await DatabaseHelper.deletePenjualan(penjualan.id!);
    await muatPenjualan();
  }

  // Memuat daftar penjualan dari database
  Future<void> muatPenjualan() async {
    // Tidak notifyListeners() sebelum await pertama: metode ini dipanggil langsung saat
    // provider dibuat (masih dalam proses build), lihat catatan yang sama di KategoriController.
    isLoading = true;
    daftarPenjualan = await DatabaseHelper.getPenjualanList();
    isLoading = false;
    notifyListeners();
  }
}
