import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/produk_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/kategori_controller.dart';
import '../models/keranjang.dart';

class KeranjangView extends StatefulWidget {
  @override
  _KeranjangViewState createState() => _KeranjangViewState();
}

class _KeranjangViewState extends State<KeranjangView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late KategoriController kategoriController;

  @override
  void initState() {
    super.initState();
    kategoriController = Provider.of<KategoriController>(context, listen: false);
    // Memuat data kategori dan produk
    Future.delayed(Duration.zero, () async {
      await kategoriController.loadKategori();
      await Provider.of<ProdukController>(context, listen: false).loadProduk();
      if (mounted) {
        setState(() {
          // Inisialisasi TabController setelah kategori dimuat
          _tabController = TabController(length: kategoriController.kategoriList.length + 1, vsync: this); // +1 untuk tab "All"
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var produkController = Provider.of<ProdukController>(context);
    var keranjangController = Provider.of<KeranjangController>(context);
    var kategoriList = kategoriController.kategoriList;

    // Pastikan TabController diupdate setelah kategori dimuat
    if (kategoriList.isNotEmpty && _tabController.length != kategoriList.length + 1) {
      _tabController = TabController(length: kategoriList.length + 1, vsync: this); // +1 untuk tab "All"
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Keranjang'),
        backgroundColor: Colors.teal,
        bottom: kategoriList.isEmpty
            ? null // Jangan tampilkan TabBar jika kategori kosong
            : TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white, // Warna indikator tab aktif
          labelColor: Colors.white, // Warna teks tab aktif
          unselectedLabelColor: Colors.white60, // Warna teks tab tidak aktif
          tabs: [
            Tab(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                color: _tabController.index == 0 ? Colors.teal : Colors.transparent, // Menambahkan background warna untuk tab aktif
                child: Text('All'),
              ),
            ),  // Tab untuk menampilkan semua produk
            ...kategoriList.map((kategori) => Tab(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                color: _tabController.index == kategoriList.indexOf(kategori) + 1 ? Colors.teal : Colors.transparent, // Warna tab kategori aktif
                child: Text(kategori.namaKategori),
              ),
            )).toList(),
          ],
        ),
      ),
      body: kategoriList.isEmpty
          ? Center(child: CircularProgressIndicator()) // Menunggu kategori dimuat
          : Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab untuk menampilkan semua produk
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Menampilkan 3 produk per baris
                      childAspectRatio: 2 / 3, // Rasio tinggi dan lebar kartu produk
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: produkController.produkList.length,
                    itemBuilder: (context, index) {
                      final produk = produkController.produkList[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              produk.namaProduk,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '\$${produk.harga.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Keranjang keranjang = Keranjang(
                                  id: produk.id!,
                                  namaProduk: produk.namaProduk,
                                  harga: produk.harga,
                                );
                                keranjangController.tambahKeKeranjang(keranjang);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: Size(80, 30),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ...kategoriList.map((kategori) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: produkController.produkList.where((produk) => produk.kategoriId == kategori.id).length,
                      itemBuilder: (context, index) {
                        final produk = produkController.produkList
                            .where((produk) => produk.kategoriId == kategori.id)
                            .toList();

                        if (produk.isEmpty) {
                          return Container(); // Kembalikan Container kosong jika tidak ada produk
                        }

                        // Jika produk ditemukan, ambil produk pertama yang sesuai
                        final item = produk.first;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.namaProduk,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '\$${item.harga.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Keranjang keranjang = Keranjang(
                                    id: item.id!,
                                    namaProduk: item.namaProduk,
                                    harga: item.harga,
                                  );
                                  keranjangController.tambahKeKeranjang(keranjang);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  minimumSize: Size(80, 30),
                                ),
                                child: Text(
                                  'Add',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // Bagian bawah: Tombol Checkout
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${keranjangController.totalItem} item - \$${keranjangController.totalHarga.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.shopping_cart_checkout, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
