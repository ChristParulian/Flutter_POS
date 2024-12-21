import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/kategori_controller.dart';
import '../models/kategori.dart';

class KategoriView extends StatefulWidget {
  @override
  _KategoriViewState createState() => _KategoriViewState();
}

class _KategoriViewState extends State<KategoriView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Memuat kategori saat pertama kali tampil
    Provider.of<KategoriController>(context, listen: false).loadKategori();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kategori'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Menambahkan kategori baru
              _showAddDialog(context);
            },
            child: Text('Tambah Kategori'),
          ),
          Expanded(
            child: Consumer<KategoriController>(
              builder: (context, kategoriController, child) {
                if (kategoriController.kategoriList.isEmpty) {
                  return Center(child: Text('Belum ada kategori.'));
                }

                return ListView.builder(
                  itemCount: kategoriController.kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = kategoriController.kategoriList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text('${index + 1}. '), // Menampilkan nomor
                            Text(kategori.namaKategori),
                          ],
                        ),
                        contentPadding: EdgeInsets.all(16),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Edit
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _controller.text = kategori.namaKategori;
                                _showUpdateDialog(context, kategori);
                              },
                            ),
                            // Tombol Delete dengan dialog konfirmasi
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(context, kategori);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dialog untuk menambah kategori
  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Kategori'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String kategoriName = _controller.text;
                if (kategoriName.isNotEmpty) {
                  Kategori kategori = Kategori(namaKategori: kategoriName);
                  Provider.of<KategoriController>(context, listen: false)
                      .addKategori(kategori);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori berhasil ditambahkan!')),
                  );
                  _controller.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.clear();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk mengupdate kategori
  void _showUpdateDialog(BuildContext context, Kategori kategori) {
    _controller.text = kategori.namaKategori;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Kategori'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String kategoriName = _controller.text;
                if (kategoriName.isNotEmpty) {
                  kategori.namaKategori = kategoriName;
                  Provider.of<KategoriController>(context, listen: false)
                      .updateKategori(kategori);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori berhasil diperbarui!')),
                  );
                  _controller.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.clear();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk menghapus kategori
  void _showDeleteDialog(BuildContext context, Kategori kategori) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Kategori'),
          content: Text('Apakah Anda yakin ingin menghapus kategori ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<KategoriController>(context, listen: false)
                    .deleteKategori(kategori.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kategori berhasil dihapus!')),
                );
                Navigator.pop(context);
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
