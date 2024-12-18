import 'package:flutter/material.dart';

// Kelas untuk tampilan tambah kategori
class TambahKategoriView extends StatefulWidget {
  final Function(String) addKategori; // Fungsi untuk menambah kategori

  TambahKategoriView({required this.addKategori});

  @override
  _TambahKategoriViewState createState() => _TambahKategoriViewState();
}

class _TambahKategoriViewState extends State<TambahKategoriView> {
  final TextEditingController _controller = TextEditingController(); // Controller untuk TextField

  // Fungsi untuk menyimpan kategori saat tombol simpan ditekan
  void _saveKategori() {
    String kategori = _controller.text.trim(); // Mengambil teks dari input

    // Validasi input, pastikan tidak kosong
    if (kategori.isNotEmpty) {
      widget.addKategori(kategori); // Panggil fungsi untuk menambah kategori
      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah simpan
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama kategori tidak boleh kosong')), // Tampilkan pesan error jika kosong
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Kategori'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Field input untuk nama kategori
            TextField(
              controller: _controller, // Menghubungkan controller
              decoration: InputDecoration(labelText: 'Nama Kategori'),
            ),
            SizedBox(height: 20),
            // Tombol Simpan
            ElevatedButton(
              onPressed: _saveKategori, // Panggil fungsi _saveKategori saat tombol ditekan
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
