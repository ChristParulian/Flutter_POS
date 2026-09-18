import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/pengaturan.dart';

// Memegang identitas toko (nama + alamat) yang tampil di Beranda dan dicetak di struk.
// Dimuat sekali saat aplikasi start, lalu di-update lewat dialog edit di Beranda.
class PengaturanController extends ChangeNotifier {
  PengaturanToko _pengaturan = const PengaturanToko(namaToko: 'Smart Toko');

  PengaturanToko get pengaturan => _pengaturan;
  String get namaToko => _pengaturan.namaToko;
  String get alamatToko => _pengaturan.alamatToko;
  String? get logoPath => _pengaturan.logoPath;

  Future<void> muatPengaturan() async {
    final hasil = await DatabaseHelper.getPengaturan();
    if (hasil != null) _pengaturan = hasil;
    notifyListeners();
  }

  Future<void> simpan(PengaturanToko baru) async {
    try {
      await DatabaseHelper.simpanPengaturan(baru);
      _pengaturan = baru;
      notifyListeners();
    } catch (e) {
      print('PengaturanController.simpan error: $e');
      rethrow;
    }
  }
}
