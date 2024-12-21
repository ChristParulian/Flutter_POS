import 'package:flutter/material.dart';

class KeranjangView extends StatefulWidget {
  @override
  _KeranjangViewState createState() => _KeranjangViewState();
}

class _KeranjangViewState extends State<KeranjangView> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  final Map<String, List<String>> kategoriProduk = {
    'All': ['Produk 1', 'Produk 2', 'Produk 3', 'Produk 4', 'Produk 5', 'Produk 6', 'Produk 7', 'Produk 8', 'Produk 9', 'Produk 10', 'Produk 11', 'Produk 12'],
    'Kategori 1': ['Produk 1', 'Produk 2', 'Produk 3'],
    'Kategori 2': ['Produk 4', 'Produk 5', 'Produk 6'],
    'Kategori 3': ['Produk 4', 'Produk 5', 'Produk 6'],
    'Kategori 4': ['Produk 4', 'Produk 5', 'Produk 6'],
    'Kategori 5': ['Produk 4', 'Produk 5', 'Produk 6'],
  };

  List<String> keranjang = [];
  double totalHarga = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kategoriProduk.keys.length, vsync: this);
  }

  void tambahKeKeranjang(String produk, double harga) {
    setState(() {
      keranjang.add(produk);
      totalHarga += harga;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Keranjang'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,  // Membuat TabBar bisa digeser
          tabs: kategoriProduk.keys
              .map((kategori) => Tab(
            text: kategori,
          ))
              .toList(),
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Bagian atas: Daftar Produk
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: kategoriProduk.entries.map((entry) {
                final produkList = entry.value;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Menampilkan 3 produk per baris
                      childAspectRatio: 2 / 3, // Rasio tinggi dan lebar kartu
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: produkList.length,
                    itemBuilder: (context, index) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              produkList[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '\$${(index + 1) * 10}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                tambahKeKeranjang(produkList[index], (index + 1) * 10.0);
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
            ),
          ),

          // Bagian bawah: Tombol Checkout
          Container(
            padding: const EdgeInsets.all(16.0), // Padding di sekitar tombol
            color: Colors.white, // Latar belakang tombol
            child: ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman Checkout
                Navigator.pushNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16.0), // Padding teks tombol
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${keranjang.length} item - \$${totalHarga.toStringAsFixed(2)}  ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Teks menjadi putih
                    ),
                  ),
                  Icon(Icons.shopping_cart_checkout, color: Colors.white), // Ikon juga putih
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
