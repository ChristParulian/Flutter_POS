import 'package:intl/intl.dart';

// Format tampilan nominal Rupiah dipakai bersama di seluruh app (kartu produk, keranjang,
// checkout, riwayat penjualan, struk) - supaya semua nominal punya pemisah ribuan titik
// yang konsisten (mis. 10.000), bukan angka mentah tanpa pemisah yang mudah salah baca.
class FormatHelper {
  static final NumberFormat _format = NumberFormat('#,##0', 'id_ID');

  static String rupiah(num value) => _format.format(value.round());

  // Teks yang diketik kasir di field harga memakai pemisah ribuan titik (mis. "10.000"),
  // jadi perlu dilepas dulu sebelum diubah ke angka. Titik dibuang tanpa peduli posisinya:
  // input hanya menerima digit dan titik (lihat RibuanInputFormatter), sehingga titik apa pun
  // di situ pasti pemisah ribuan - bukan koma desimal.
  static double? parseRibuan(String teks) {
    final bersih = teks.replaceAll('.', '').trim();
    if (bersih.isEmpty) return null;
    return double.tryParse(bersih);
  }

  // Titik ribuan versi ringkas untuk awalan input (mis. "10.000" jadi "10 rb"), dipakai di
  // tombol nominal cepat di Checkout. Hanya sampai juta: nominal lebih besar ditampilkan
  // utuh supaya nominalnya tetap terbaca persis, bukan angka bulat yang menyesatkan.
  static String ringkas(num value) {
    if (value >= 1000000) return rupiah(value);
    if (value >= 1000) return '${(value / 1000).round()} rb';
    return rupiah(value);
  }
}
