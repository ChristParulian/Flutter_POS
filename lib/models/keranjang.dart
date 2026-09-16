class Keranjang {
  int id;
  String namaProduk;
  double harga;
  int jumlah;

  Keranjang({
    required this.id,
    required this.namaProduk,
    required this.harga,
    this.jumlah = 1,
  });

  double get totalHarga => harga * jumlah;

  // Metode untuk menambah jumlah produk di keranjang
  void tambahJumlah() {
    jumlah++;
  }

  // Metode untuk mengurangi jumlah produk di keranjang
  void kurangJumlah() {
    if (jumlah > 1) {
      jumlah--;
    }
  }
}
