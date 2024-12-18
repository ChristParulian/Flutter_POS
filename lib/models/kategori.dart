class Kategori {
  int? id;
  String namaKategori;

  Kategori({this.id, required this.namaKategori});

  // Mengubah objek Kategori menjadi Map untuk disimpan di database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaKategori': namaKategori,
    };
  }

  // Membuat objek Kategori dari Map
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      namaKategori: map['namaKategori'],
    );
  }
}
