import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor FilteringTextInputFormatter
import 'package:provider/provider.dart'; // Impor Provider untuk mengakses ProdukController
import '../controllers/produk_controller.dart'; // Pastikan ProdukController diimpor
import '../controllers/kategori_controller.dart'; // Pastikan KategoriController diimpor
import '../models/produk.dart'; // Pastikan model Produk diimpor
import '../models/kategori.dart'; // Pastikan model Kategori diimpor

class ProdukView extends StatefulWidget {
  @override
  _ProdukViewState createState() => _ProdukViewState();
}

class _ProdukViewState extends State<ProdukView> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  int? _selectedKategoriId;

  @override
  void initState() {
    super.initState();
    // Memuat produk saat view pertama kali dibuka
    Future.delayed(Duration.zero, () {
      Provider.of<ProdukController>(context, listen: false).loadProduk();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inputan untuk nama produk
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),

            // Inputan untuk harga produk
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _hargaController,
                decoration: InputDecoration(
                  labelText: 'Harga Produk',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Hanya menerima angka
                ],
              ),
            ),

            // Dropdown untuk memilih kategori
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pilih Kategori',
                  border: OutlineInputBorder(),
                ),
                child: Consumer<KategoriController>( // Menambahkan Consumer untuk KategoriController
                  builder: (context, kategoriController, child) {
                    return kategoriController.kategoriList.isNotEmpty // Menambahkan pengecekan kategori
                        ? DropdownButton<int>(
                      value: _selectedKategoriId,
                      isExpanded: true,
                      onChanged: (int? newKategoriId) {
                        setState(() {
                          _selectedKategoriId = newKategoriId;
                        });
                      },
                      items: kategoriController.kategoriList
                          .map<DropdownMenuItem<int>>(
                            (kategori) => DropdownMenuItem<int>(
                          value: kategori.id, // Pastikan id ada di model Kategori
                          child: Text(kategori.namaKategori), // Pastikan namaKategori ada
                        ),
                      )
                          .toList(),
                    )
                        : Center(child: CircularProgressIndicator()); // Tampilkan loading jika kategori kosong
                  },
                ),
              ),
            ),

            // Tombol untuk simpan produk
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  String namaProduk = _namaController.text;
                  double hargaProduk = double.tryParse(_hargaController.text) ?? 0.0;

                  if (namaProduk.isNotEmpty && hargaProduk > 0 && _selectedKategoriId != null) {
                    Produk produk = Produk(
                      namaProduk: namaProduk,
                      kategoriId: _selectedKategoriId!,
                      harga: hargaProduk,
                    );

                    // Menyimpan produk ke ProdukController
                    try {
                      await Provider.of<ProdukController>(context, listen: false).addProduk(produk);
                      // Menutup form setelah berhasil menyimpan produk dan tetap di ProdukView
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Produk berhasil disimpan!'),
                      ));
                    } catch (e) {
                      // Tampilkan pesan kesalahan jika terjadi error
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Terjadi kesalahan saat menyimpan produk!'),
                      ));
                    }
                  } else {
                    // Tampilkan pesan kesalahan jika input tidak valid
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Harap isi semua data dengan benar!'),
                    ));
                  }
                },
                child: Text('Simpan Produk'),
              ),
            ),

            // Daftar Produk
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Consumer<ProdukController>(
                builder: (context, produkController, child) {
                  if (produkController.produkList.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return Consumer<KategoriController>( // Menambahkan Consumer untuk KategoriController
                    builder: (context, kategoriController, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: produkController.produkList.length,
                        itemBuilder: (context, index) {
                          Produk produk = produkController.produkList[index];
                          // Menambahkan pengecekan kategori
                          String kategoriNama = kategoriController.kategoriList.firstWhere(
                                (kategori) => kategori.id == produk.kategoriId,
                            orElse: () => Kategori(id: -1, namaKategori: 'Kategori Tidak Ditemukan'), // Kategori default
                          ).namaKategori;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('${index + 1}. ${produk.namaProduk}'), // Menambahkan nomor urut
                              subtitle: Text(
                                'Harga: ${produk.harga}\nKategori: $kategoriNama',
                              ), // Menampilkan nama kategori
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  // Konfirmasi penghapusan produk
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
                                  }
                                },
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
}
