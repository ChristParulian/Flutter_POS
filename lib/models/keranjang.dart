class Keranjang {
  final int id;
  final String namaProduk;
  final double harga;
  int jumlah;

  Keranjang({
    required this.id,
    required this.namaProduk,
    required this.harga,
    this.jumlah = 1,
  });

  // Menambah jumlah jika produk sudah ada dalam keranjang
  void tambahJumlah() {
    jumlah++;
  }

  // Menghitung total harga untuk item ini
  double get totalHarga => harga * jumlah;
}
