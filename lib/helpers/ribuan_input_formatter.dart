import 'package:flutter/services.dart';
import 'format_helper.dart';

// Mengetik harga "10000" sambil menampilkan "10.000" - titik ribuan muncul sendiri saat
// diketik dan hilang lagi saat dihapus, jadi kasir tidak perlu memikirkan format.
// Titik yang menyusup dari tempel (paste) dibuang dulu, sehingga "10.000" yang ditempel
// tetap terbaca 10000, bukan menambah digit.
class RibuanInputFormatter extends TextInputFormatter {
  // Batas digit ini untuk mencegah angka kelewat besar yang bisa meluberkan tampilan dan
  // mengubah nilai jadi notasi ilmiah (mis. 1e+21) yang tidak bisa dibaca sebagai Rupiah.
  static const int maxDigit = 12;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digit = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Seleksi dipertahankan pada digit yang sama (bukan pada posisi karakter yang sama) supaya
    // kursor tidak melompat ke ujung setiap kali pemisah ribuan ditambahkan atau dihapus.
    final digitSampaiKursor = newValue.text
        .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    if (digit.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    if (digit.length > maxDigit) {
      return oldValue;
    }

    final angka = int.parse(digit);
    final teksBaru = FormatHelper.rupiah(angka);
    final offsetBaru = _posisiSetelahDigit(teksBaru, digitSampaiKursor);

    return TextEditingValue(
      text: teksBaru,
      selection: TextSelection.collapsed(offset: offsetBaru),
    );
  }

  // Mencari posisi kursor yang jatuh tepat setelah digit ke-[n]. Dipakai untuk memulihkan
  // posisi kursor setelah teks diformat ulang.
  static int _posisiSetelahDigit(String teks, int n) {
    if (n <= 0) return 0;
    var terhitung = 0;
    for (var i = 0; i < teks.length; i++) {
      if (teks[i] != '.') {
        terhitung++;
        if (terhitung == n) return i + 1;
      }
    }
    return teks.length;
  }
}