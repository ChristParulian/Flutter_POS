import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/produk_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../models/produk.dart';
import '../models/keranjang.dart';

class KeranjangView extends StatefulWidget {
  @override
  _KeranjangViewState createState() => _KeranjangViewState();
}

class _KeranjangViewState extends State<KeranjangView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController and other setup here
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Keranjang'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2 / 3,
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
