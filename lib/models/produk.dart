class Produk {
  int? id;
  String namaProduk;
  double harga;
  int kategoriId;

  Produk({
    this.id,
    required this.namaProduk,
    required this.harga,
    required this.kategoriId,
  });

  // Fungsi untuk mengubah objek menjadi map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaProduk': namaProduk,
      'harga': harga,
      'kategoriId': kategoriId,
    };
  }

  // Fungsi untuk mengubah map menjadi objek
  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'],
      namaProduk: map['namaProduk'],
      harga: map['harga'],
      kategoriId: map['kategoriId'],
    );
  }
}
