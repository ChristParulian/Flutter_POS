import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/produk_controller.dart';
import 'controllers/kategori_controller.dart';
import 'controllers/keranjang_controller.dart';
import 'controllers/penjualan_controller.dart';
import 'views/produk_view.dart';
import 'views/kategori_view.dart';
import 'views/keranjang_view.dart';
import 'views/checkout_view.dart';
import 'views/penjualan_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<KategoriController>(
          create: (context) => KategoriController()..loadKategori(),
        ),
        ChangeNotifierProvider<ProdukController>(
          create: (context) => ProdukController()..loadProduk(),
        ),
        ChangeNotifierProvider<KeranjangController>(
          create: (context) => KeranjangController(),
        ),
        ChangeNotifierProvider<PenjualanController>(
          create: (context) => PenjualanController(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => MenuPage(),
          '/kategori': (context) => KategoriView(),
          '/produk': (context) => ProdukView(),
          '/keranjang': (context) => KeranjangView(),
          '/checkout': (context) => CheckoutView(),
          '/penjualan': (context) => PenjualanView(),
        },
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Toko',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber, // Ubah menjadi kuning emas
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            Center(
              child: Text(
                'Selamat datang di Smart Toko!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 20),
            _buildMenuButton(
              context,
              label: 'Kelola Kategori',
              route: '/kategori',
              icon: Icons.category,
            ),
            _buildMenuButton(
              context,
              label: 'Kelola Produk',
              route: '/produk',
              icon: Icons.shopping_basket,
            ),
            _buildMenuButton(
              context,
              label: 'Kelola Sales',
              route: '/keranjang',
              icon: Icons.shopping_cart,
            ),
            _buildMenuButton(
              context,
              label: 'Lihat Penjualan',
              route: '/penjualan',
              icon: Icons.receipt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, {
        required String label,
        required String route,
        required IconData icon,
      }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(
            icon,
            color: Colors.amber, // Ubah warna ikon menjadi kuning emas
            size: 30,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87, // Warna teks tetap gelap agar terbaca
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.amber, // Ubah warna ikon trailing menjadi kuning emas
          ),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }
}
