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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<KategoriController>(context, listen: false).loadKategori();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(vertical: 14.0),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tambah Kategori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  // Rebuild with filtered list
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari Kategori...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Menambahkan teks "Daftar Kategori" di atas list kategori
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Daftar Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Consumer<KategoriController>(
              builder: (context, kategoriController, child) {
                // Filter the kategori list based on search query
                String searchQuery = _searchController.text.toLowerCase();
                var filteredList = kategoriController.kategoriList
                    .where((kategori) =>
                    kategori.namaKategori.toLowerCase().contains(searchQuery))
                    .toList();

                if (filteredList.isEmpty) {
                  return Center(child: Text('Tidak ada kategori yang ditemukan.'));
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final kategori = filteredList[index];
                    return InkWell(
                      onTap: () {},
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ExpansionTile(
                              title: Row(
                                children: [
                                  Text('${index + 1}. ', style: TextStyle(fontSize: 16)),
                                  Text(kategori.namaKategori, style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_drop_down),
                              children: [
                                ListTile(
                                  title: Text(
                                    "Update",
                                    style: TextStyle(color: Colors.amber),
                                  ),
                                  onTap: () {
                                    _controller.text = kategori.namaKategori;
                                    _showUpdateDialog(context, kategori);
                                  },
                                ),
                                ListTile(
                                  title: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    _showDeleteDialog(context, kategori);
                                  },
                                ),
                              ],
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambah Kategori',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Batal', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        String kategoriName = _controller.text;
                        if (kategoriName.isNotEmpty) {
                          Kategori kategori = Kategori(namaKategori: kategoriName);
                          Provider.of<KategoriController>(context, listen: false)
                              .addKategori(kategori);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Kategori berhasil ditambahkan!'),
                          ));
                          _controller.clear();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Simpan', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Kategori',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.clear();
                      },
                      child: Text('Batal', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        String kategoriName = _controller.text;
                        if (kategoriName.isNotEmpty) {
                          kategori.namaKategori = kategoriName;
                          Provider.of<KategoriController>(context, listen: false)
                              .updateKategori(kategori);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Kategori berhasil diperbarui!'),
                          ));
                          _controller.clear();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Simpan', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog untuk menghapus kategori
  void _showDeleteDialog(BuildContext context, Kategori kategori) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hapus Kategori',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Apakah Anda yakin ingin menghapus kategori ini ?',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Batal', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<KategoriController>(context, listen: false)
                            .deleteKategori(kategori.id!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Kategori berhasil dihapus!'),
                        ));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Hapus', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

