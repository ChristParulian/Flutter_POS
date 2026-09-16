import 'package:intl/intl.dart';
import '../models/keranjang.dart';

class Penjualan {
  int? id;
  DateTime tanggal;
  double totalHarga;
  double jumlahDibayar;
  double kembalian;
  List<Keranjang> daftarProduk;

  Penjualan({
    this.id,
    required this.tanggal,
    required this.totalHarga,
    required this.jumlahDibayar,
    required this.kembalian,
    required this.daftarProduk,
  });

  String get formattedTanggal {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(tanggal);
  }

  // Mengubah data induk penjualan menjadi map (tanpa daftar item, disimpan di tabel terpisah)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'totalHarga': totalHarga,
      'jumlahDibayar': jumlahDibayar,
      'kembalian': kembalian,
    };
  }

  factory Penjualan.fromMap(Map<String, dynamic> map, List<Keranjang> daftarProduk) {
    return Penjualan(
      id: map['id'],
      tanggal: DateTime.parse(map['tanggal']),
      totalHarga: map['totalHarga'],
      jumlahDibayar: map['jumlahDibayar'],
      kembalian: map['kembalian'],
      daftarProduk: daftarProduk,
    );
  }
}
