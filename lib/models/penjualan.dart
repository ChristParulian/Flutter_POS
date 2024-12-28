import 'package:intl/intl.dart';
import '../models/keranjang.dart';

class Penjualan {
  DateTime tanggal;
  double totalHarga;
  double jumlahDibayar;
  double kembalian;
  List<Keranjang> daftarProduk;

  Penjualan({
    required this.tanggal,
    required this.totalHarga,
    required this.jumlahDibayar,
    required this.kembalian,
    required this.daftarProduk,
  });

  String get formattedTanggal {
    return DateFormat('yyyy-MM-dd').format(tanggal);
  }

  // Mengonversi objek Penjualan menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal.toIso8601String(),
      'totalHarga': totalHarga,
      'jumlahDibayar': jumlahDibayar,
      'kembalian': kembalian,
      'daftarProduk': daftarProduk.map((produk) => produk.toJson()).toList(),
    };
  }

  // Mengonversi JSON menjadi objek Penjualan
  factory Penjualan.fromJson(Map<String, dynamic> json) {
    return Penjualan(
      tanggal: DateTime.parse(json['tanggal']),
      totalHarga: json['totalHarga'],
      jumlahDibayar: json['jumlahDibayar'],
      kembalian: json['kembalian'],
      daftarProduk: (json['daftarProduk'] as List)
          .map((item) => Keranjang.fromJson(item)) // Memastikan Keranjang punya fromJson
          .toList(),
    );
  }
}
