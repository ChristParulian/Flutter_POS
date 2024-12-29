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
  int? _selectedKategoriId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Membuat teks menjadi bold
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol Tambah Produk
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showTambahProdukDialog(context);
                },
                label: Text('Tambah Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Dropdown Filter Kategori
            Consumer<KategoriController>(
              builder: (context, kategoriController, child) {
                return DropdownButtonFormField<int?>(
                  value: _selectedKategoriId,
                  decoration: InputDecoration(
                    labelText: 'Filter Kategori',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedKategoriId = newValue;
                    });
                  },
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Kategori'),
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
            SizedBox(height: 16.0),

            // Daftar Produk
            Expanded(
              child: Consumer<ProdukController>(
                builder: (context, produkController, child) {
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
                      String kategoriNama = Provider.of<KategoriController>(context, listen: false)
                          .kategoriList
                          .firstWhere(
                            (kategori) => kategori.id == produk.kategoriId,
                        orElse: () => Kategori(
                          id: -1,
                          namaKategori: 'Kategori Tidak Ditemukan',
                        ),
                      )
                          .namaKategori;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                          title: Text(
                            '${index + 1}. ${produk.namaProduk}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Harga: Rp ${produk.harga.toStringAsFixed(0)}\nKategori: $kategoriNama',
                          ),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _showEditProdukDialog(context, produk);
                                  },
                                  child: Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    bool? confirmDelete = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Konfirmasi Hapus'),
                                        content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: Text('Batal', style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text('Hapus', style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmDelete == true) {
                                      await Provider.of<ProdukController>(context, listen: false)
                                          .deleteProduk(produk.id!);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Produk berhasil dihapus!'),
                                        backgroundColor: Colors.amber,
                                      ));
                                    }
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),


                              ],
                            ),
                          ],
                        ),
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
      builder: (context) => AlertDialog(
        title: Text('Tambah Produk',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Produk'),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Harga Produk'),
              ),
              SizedBox(height: 8.0),
              Consumer<KategoriController>(
                builder: (context, kategoriController, child) {
                  return DropdownButtonFormField<int>(
                    value: selectedKategoriId,
                    decoration: InputDecoration(labelText: 'Pilih Kategori'),
                    onChanged: (value) {
                      selectedKategoriId = value;
                    },
                    items: kategoriController.kategoriList.map((kategori) {
                      return DropdownMenuItem<int>(
                        value: kategori.id,
                        child: Text(kategori.namaKategori),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
              ),),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaController.text.isNotEmpty && hargaController.text.isNotEmpty && selectedKategoriId != null) {
                Produk produk = Produk(
                  namaProduk: namaController.text,
                  kategoriId: selectedKategoriId!,
                  harga: double.parse(hargaController.text),
                );
                Provider.of<ProdukController>(context, listen: false).addProduk(produk);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Produk berhasil ditambahkan!'),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Simpan',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),),
          ),
        ],
      ),
    );
  }

  // Dialog Edit Produk (Sama dengan Tambah Produk tapi mengisi data awal)
  void _showEditProdukDialog(BuildContext context, Produk produk) {
    final TextEditingController namaController = TextEditingController(text: produk.namaProduk);
    final TextEditingController hargaController = TextEditingController(text: produk.harga.toString());
    int? selectedKategoriId = produk.kategoriId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Produk'),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Harga Produk'),
              ),
              SizedBox(height: 8.0),
              Consumer<KategoriController>(
                builder: (context, kategoriController, child) {
                  return DropdownButtonFormField<int>(
                    value: selectedKategoriId,
                    decoration: InputDecoration(labelText: 'Pilih Kategori'),
                    onChanged: (value) {
                      selectedKategoriId = value;
                    },
                    items: kategoriController.kategoriList.map((kategori) {
                      return DropdownMenuItem<int>(
                        value: kategori.id,
                        child: Text(kategori.namaKategori),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal',
            style:
              TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              ),),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaController.text.isNotEmpty && hargaController.text.isNotEmpty && selectedKategoriId != null) {
                produk.namaProduk = namaController.text;
                produk.harga = double.parse(hargaController.text);
                produk.kategoriId = selectedKategoriId!;
                Provider.of<ProdukController>(context, listen: false).updateProduk(produk);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Produk berhasil diperbarui!'),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Simpan',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
            ),),
          ),
        ],
      ),
    );
  }
}
