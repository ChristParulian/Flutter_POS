class Produk {
  int? id;
  String namaProduk;
  double harga;
  int kategoriId;
  int stok;
  String? barcode;
  String? fotoProduk;

  Produk({
    this.id,
    required this.namaProduk,
    required this.harga,
    required this.kategoriId,
    this.stok = 0,
    this.barcode,
    this.fotoProduk,
  });

  // Fungsi untuk mengubah objek menjadi map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaProduk': namaProduk,
      'harga': harga,
      'kategoriId': kategoriId,
      'stok': stok,
      'barcode': barcode,
      'fotoProduk': fotoProduk,
    };
  }

  // Fungsi untuk mengubah map menjadi objek
  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'],
      namaProduk: map['namaProduk'],
      harga: map['harga'],
      kategoriId: map['kategoriId'],
      stok: map['stok'] ?? 0,
      barcode: map['barcode'],
      fotoProduk: map['fotoProduk'],
    );
  }
}
