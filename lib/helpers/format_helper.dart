import 'package:intl/intl.dart';

// Format tampilan nominal Rupiah dipakai bersama di seluruh app (kartu produk, keranjang,
// checkout, riwayat penjualan, struk) - supaya semua nominal punya pemisah ribuan titik
// yang konsisten (mis. 10.000), bukan angka mentah tanpa pemisah yang mudah salah baca.
class FormatHelper {
  static final NumberFormat _format = NumberFormat('#,##0', 'id_ID');

  static String rupiah(num value) => _format.format(value.round());
}
