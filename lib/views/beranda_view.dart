import 'package:flutter/material.dart';

// Halaman menu awal: tempat menyapa dan titik masuk cepat ke setiap bagian aplikasi.
// Kartu di sini sengaja seragam (bukan warna-warni per kartu) supaya sesuai arah desain
// "Bersih & Profesional" - identitas datang dari kejelasan, bukan dekorasi.
// Indeks tab mengikuti urutan _tabs di HomeShell (main.dart): 0 Beranda, 1 Kategori,
// 2 Produk, 3 Keranjang, 4 Penjualan.
class BerandaView extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const BerandaView({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem('Kelola Kategori', Icons.category_outlined, () => onNavigateToTab(1)),
      _MenuItem('Kelola Produk', Icons.shopping_basket_outlined, () => onNavigateToTab(2)),
      _MenuItem('Keranjang', Icons.shopping_cart_outlined, () => onNavigateToTab(3)),
      _MenuItem('Riwayat Penjualan', Icons.receipt_long_outlined, () => onNavigateToTab(4)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Toko')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 44, height: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selamat datang kembali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Kelola toko Anda dari sini', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.amber.shade50,
                                child: Icon(item.icon, color: Colors.amber.shade700, size: 26),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _MenuItem(this.label, this.icon, this.onTap);
}
