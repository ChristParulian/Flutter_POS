import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/produk_controller.dart';
import '../controllers/kategori_controller.dart';
import '../models/produk.dart';
import '../models/kategori.dart';

class ProdukView extends StatefulWidget {
  @override
  _ProdukViewState createState() => _ProdukViewState();
}

class _ProdukViewState extends State<ProdukView> {
  int? _selectedKategoriId; // Menyimpan ID kategori yang dipilih (null untuk 'All')

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol untuk menambahkan produk
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  _showTambahProdukDialog(context);
                },
                child: Text('Tambah Produk'),
              ),
            ),
            SizedBox(height: 16.0),

            // Dropdown untuk filter kategori
            Consumer<KategoriController>(
              builder: (context, kategoriController, child) {
                return DropdownButtonFormField<int?>(
                  value: _selectedKategoriId,
                  decoration: InputDecoration(labelText: 'Filter Kategori'),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedKategoriId = newValue;
                    });
                  },
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All'), // Opsi untuk menampilkan semua produk
                    ),
                    ...kategoriController.kategoriList.map(
                          (kategori) => DropdownMenuItem<int?>(
                        value: kategori.id,
                        child: Text(kategori.namaKategori),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 16.0), // Jarak antara dropdown dan daftar produk

            // Daftar Produk
            Expanded(
              child: Consumer<ProdukController>(
                builder: (context, produkController, child) {
                  if (produkController.produkList.isEmpty) {
                    return Center(child: Text('Tidak ada produk.'));
                  }

                  return Consumer<KategoriController>(
                    builder: (context, kategoriController, child) {
                      // Filter produk berdasarkan kategori yang dipilih
                      List<Produk> filteredProdukList = _selectedKategoriId == null
                          ? produkController.produkList
                          : produkController.produkList.where((produk) {
                        return produk.kategoriId == _selectedKategoriId;
                      }).toList();

                      if (filteredProdukList.isEmpty) {
                        return Center(
                          child: Text('Tidak ada produk untuk kategori yang dipilih.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredProdukList.length,
                        itemBuilder: (context, index) {
                          Produk produk = filteredProdukList[index];
                          String kategoriNama = kategoriController.kategoriList.firstWhere(
                                (kategori) => kategori.id == produk.kategoriId,
                            orElse: () => Kategori(
                              id: -1,
                              namaKategori: 'Kategori Tidak Ditemukan',
                            ),
                          ).namaKategori;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('${index + 1}. ${produk.namaProduk}'),
                              subtitle: Text(
                                'Harga: ${produk.harga}\nKategori: $kategoriNama',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Edit
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _showEditProdukDialog(context, produk, kategoriController);
                                    },
                                  ),
                                  // Tombol Delete
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      bool? confirmDelete = await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('Konfirmasi Hapus'),
                                            content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(false);
                                                },
                                                child: Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(true);
                                                },
                                                child: Text('Hapus'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmDelete == true) {
                                        await produkController.deleteProduk(produk.id!);

                                        // Menampilkan pesan setelah produk dihapus
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Produk berhasil dihapus!'),
                                        ));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Tambah Produk
  void _showTambahProdukDialog(BuildContext context) {
    final TextEditingController namaController = TextEditingController();
    final TextEditingController hargaController = TextEditingController();
    int? selectedKategoriId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Nama Produk
                TextFormField(
                  controller: namaController,
                  decoration: InputDecoration(labelText: 'Nama Produk'),
                ),
                SizedBox(height: 8.0),

                // Input Harga Produk
                TextFormField(
                  controller: hargaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Harga Produk'),
                ),
                SizedBox(height: 8.0),

                // Dropdown Kategori
                Consumer<KategoriController>(
                  builder: (context, kategoriController, child) {
                    return DropdownButtonFormField<int>(
                      value: selectedKategoriId,
                      decoration: InputDecoration(labelText: 'Pilih Kategori'),
                      onChanged: (int? newKategoriId) {
                        selectedKategoriId = newKategoriId;
                      },
                      items: kategoriController.kategoriList
                          .map<DropdownMenuItem<int>>(
                            (kategori) => DropdownMenuItem<int>(
                          value: kategori.id,
                          child: Text(kategori.namaKategori),
                        ),
                      )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                String namaProduk = namaController.text;
                double hargaProduk = double.tryParse(hargaController.text) ?? 0.0;

                if (namaProduk.isNotEmpty && hargaProduk > 0 && selectedKategoriId != null) {
                  Produk produk = Produk(
                    namaProduk: namaProduk,
                    kategoriId: selectedKategoriId!,
                    harga: hargaProduk,
                  );

                  // Tambahkan produk melalui controller
                  await Provider.of<ProdukController>(context, listen: false).addProduk(produk);

                  Navigator.of(context).pop(); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Produk berhasil ditambahkan!'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Harap isi semua data dengan benar!'),
                  ));
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog Edit Produk
  void _showEditProdukDialog(
      BuildContext context, Produk produk, KategoriController kategoriController) {
    final TextEditingController namaController = TextEditingController(text: produk.namaProduk);
    final TextEditingController hargaController = TextEditingController(text: produk.harga.toString());
    int? selectedKategoriId = produk.kategoriId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Nama Produk
                TextFormField(
                  controller: namaController,
                  decoration: InputDecoration(labelText: 'Nama Produk'),
                ),
                SizedBox(height: 8.0),

                // Input Harga Produk
                TextFormField(
                  controller: hargaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Harga Produk'),
                ),
                SizedBox(height: 8.0),

                // Dropdown Kategori
                Consumer<KategoriController>(
                  builder: (context, kategoriController, child) {
                    return DropdownButtonFormField<int>(
                      value: selectedKategoriId,
                      decoration: InputDecoration(labelText: 'Pilih Kategori'),
                      onChanged: (int? newKategoriId) {
                        selectedKategoriId = newKategoriId;
                      },
                      items: kategoriController.kategoriList
                          .map<DropdownMenuItem<int>>(
                            (kategori) => DropdownMenuItem<int>(
                          value: kategori.id,
                          child: Text(kategori.namaKategori),
                        ),
                      )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                String namaProduk = namaController.text;
                double hargaProduk = double.tryParse(hargaController.text) ?? 0.0;

                if (namaProduk.isNotEmpty && hargaProduk > 0 && selectedKategoriId != null) {
                  Produk updatedProduk = Produk(
                    id: produk.id,  // Menjaga ID produk yang sama
                    namaProduk: namaProduk,
                    kategoriId: selectedKategoriId!,
                    harga: hargaProduk,
                  );

                  // Update produk melalui controller
                  await Provider.of<ProdukController>(context, listen: false).updateProduk(updatedProduk);

                  Navigator.of(context).pop(); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Produk berhasil diperbarui!'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Harap isi semua data dengan benar!'),
                  ));
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
