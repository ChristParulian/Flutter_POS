import 'package:flutter/material.dart';
import '../models/keranjang.dart';

class KeranjangController with ChangeNotifier {
  List<Keranjang> _keranjangList = [];

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


  double get totalHarga => _keranjangList.fold(0, (total, item) => total + item.totalHarga);
  int get totalItem => _keranjangList.fold(0, (count, item) => count + item.jumlah);
}
