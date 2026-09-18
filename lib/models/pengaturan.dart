// Identitas toko yang dicetak di header struk dan bisa diubah dari halaman Beranda.
// Disimpan sebagai satu baris tunggal (id=1) di tabel `pengaturan` - lihat DatabaseHelper.
class PengaturanToko {
  final String namaToko;
  final String alamatToko;
  final String? logoPath;

  const PengaturanToko(
      {required this.namaToko, this.alamatToko = '', this.logoPath});

  Map<String, dynamic> toMap() => {
        'namaToko': namaToko,
        'alamatToko': alamatToko,
        'logoPath': logoPath,
      };

  factory PengaturanToko.fromMap(Map<String, dynamic> map) => PengaturanToko(
        namaToko: map['namaToko'] as String? ?? 'Smart Toko',
        alamatToko: map['alamatToko'] as String? ?? '',
        logoPath: map['logoPath'] as String?,
      );
}
