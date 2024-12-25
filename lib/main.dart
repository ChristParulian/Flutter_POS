import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/produk_controller.dart';
import 'controllers/kategori_controller.dart';
import 'controllers/keranjang_controller.dart'; // Tambahkan controller untuk keranjang
import 'views/produk_view.dart';
import 'views/kategori_view.dart';
import 'views/keranjang_view.dart';
import 'views/checkout_view.dart'; // Import CheckoutView

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
        ChangeNotifierProvider<KeranjangController>( // Tambahkan provider untuk KeranjangController
          create: (context) => KeranjangController(),
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
          '/checkout': (context) => CheckoutView(), // Routing untuk CheckoutView
        },
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Utama')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/kategori');
              },
              child: Text('Kelola Kategori'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/produk');
              },
              child: Text('Kelola Produk'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/keranjang'); // Navigasi ke Keranjang
              },
              child: Text('Kelola Keranjang'), // Button untuk Kelola Keranjang
            ),
          ],
        ),
      ),
    );
  }
}
