import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/kategori_controller.dart';
import 'views/kategori_view.dart'; // Import kategori view

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => KategoriController()..loadKategori(), // Memuat kategori saat aplikasi dimulai
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/', // Set initial route ke halaman menu
        routes: {
          '/': (context) => MenuPage(), // Halaman menu utama
          '/kategori': (context) => KategoriView(), // Halaman kategori
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
        title: Text('Menu Utama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Routing ke halaman kategori
                Navigator.pushNamed(context, '/kategori');
              },
              child: Text('Kelola Kategori'),
            ),
            // Bisa ditambahkan menu lainnya nanti seperti produk, penjualan, dsb.
          ],
        ),
      ),
    );
  }
}
