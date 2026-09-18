import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/penjualan_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/produk_controller.dart';
import '../controllers/pengaturan_controller.dart';
import '../helpers/format_helper.dart';
import '../helpers/foto_helper.dart';
import '../models/penjualan.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';
import '../models/pengaturan.dart';

// Halaman beranda: menyapa kasir dengan data nyata hari ini (ringkasan penjualan,
// keranjang yang masih berjalan, produk yang stoknya menipis) lalu titik masuk cepat ke
// tiap bagian aplikasi. Flat dan netral: informasi didahulukan, dekorasi tidak dipakai.
// Indeks tab mengikuti urutan _tabs di HomeShell (main.dart): 0 Beranda, 1 Kategori,
// 2 Produk, 3 Keranjang, 4 Penjualan.
class BerandaView extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const BerandaView({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Judul AppBar = nama toko dari pengaturan; tombol pensil di sebelahnya untuk
      // mengubah nama & alamat toko. Nilai yang sama dipakai di header struk.
      appBar: AppBar(
        title: Consumer<PengaturanController>(
          builder: (context, pengaturan, child) => Text(
            pengaturan.namaToko,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ubah nama & alamat toko',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _bukaDialogEditToko(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              // Logo toko: pakai logo kustom dari pengaturan kalau ada, kalau belum ada
              // (atau file-nya hilang) kembali ke logo bawaan aplikasi.
              Consumer<PengaturanController>(
                builder: (context, pengaturan, child) => _LogoBeranda(
                  logoPath: pengaturan.logoPath,
                  size: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat datang kembali',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Kelola toko Anda dari sini',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<PenjualanController>(
            builder: (context, penjualanController, child) => _RingkasanHariIni(
              penjualanList: penjualanController.daftarPenjualan,
            ),
          ),
          const SizedBox(height: 20),
          Consumer<KeranjangController>(
            builder: (context, keranjangController, child) =>
                _KeranjangBerjalan(
              keranjangList: keranjangController.keranjangList,
              totalHarga: keranjangController.totalHarga,
              onLanjutkan: () => onNavigateToTab(3),
            ),
          ),
          const SizedBox(height: 20),
          const _JudulBagian('Menu'),
          const SizedBox(height: 8),
          _GridMenu(
            menuItems: [
              _MenuItem('Kelola Kategori', Icons.category_outlined,
                  () => onNavigateToTab(1)),
              _MenuItem('Kelola Produk', Icons.shopping_basket_outlined,
                  () => onNavigateToTab(2)),
              _MenuItem('Keranjang', Icons.shopping_cart_outlined,
                  () => onNavigateToTab(3)),
              _MenuItem('Riwayat Penjualan', Icons.receipt_long_outlined,
                  () => onNavigateToTab(4)),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<ProdukController>(
            builder: (context, produkController, child) => _StokMenipis(
              produkList: produkController.produkList,
              onLihatProduk: () => onNavigateToTab(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Dialog edit identitas toko (nama + alamat + logo). Nilai yang disimpan dipakai
  // langsung sebagai header struk - lihat StrukHelper. Logo dikelola terpisah dari
  // teks: pilih logo baru akan menyalin file-nya ke folder aplikasi (via FotoHelper)
  // dan menyimpan path-nya, sedangkan "Hapus" kembali ke logo bawaan aplikasi.
  Future<void> _bukaDialogEditToko(BuildContext context) async {
    final controller = context.read<PengaturanController>();
    final namaController = TextEditingController(text: controller.namaToko);
    final alamatController = TextEditingController(text: controller.alamatToko);
    // Logo yang sedang dipilih di dialog; null berarti pakai logo bawaan.
    String? logoDipilih = controller.logoPath;

    final tersimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Identitas Toko'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _LogoBeranda(logoPath: logoDipilih, size: 56),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Logo toko (opsional)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () => _pilihLogo(dialogContext, setDialogState,
                        (path) => logoDipilih = path),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Pilih'),
                  ),
                  if (logoDipilih != null)
                    IconButton(
                      tooltip: 'Hapus logo (kembali ke logo bawaan)',
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => setDialogState(() => logoDipilih = null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama toko'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatController,
                decoration:
                    const InputDecoration(labelText: 'Alamat toko (opsional)'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    // Baca nilai sebelum dispose supaya controller masih hidup saat teksnya dipakai.
    final nama = namaController.text.trim();
    final alamat = alamatController.text.trim();
    final logoAsli = controller.logoPath;
    namaController.dispose();
    alamatController.dispose();

    if (!context.mounted) return;
    if (tersimpan != true) {
      // Dialog ditutup tanpa disimpan tapi sempat memilih logo baru: hapus file yang
      // sudah ter-copy supaya tidak jadi sampah tak terpakai.
      if (logoDipilih != null && logoDipilih != logoAsli) {
        await FotoHelper.hapusFotoJikaAda(logoDipilih);
      }
      return;
    }
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama toko tidak boleh kosong')),
      );
      return;
    }
    // Logo lama diganti: hapus file lamanya supaya tidak menumpuk di folder aplikasi.
    if (logoAsli != null && logoDipilih != logoAsli) {
      await FotoHelper.hapusFotoJikaAda(logoAsli);
    }
    try {
      await controller.simpan(PengaturanToko(
          namaToko: nama, alamatToko: alamat, logoPath: logoDipilih));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menyimpan identitas toko: ${e.toString()}')),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identitas toko disimpan')),
    );
  }

  // Pilih logo baru dari kamera/galeri (pola sama dengan foto produk di produk_view),
  // salin ke folder aplikasi, lalu beri tahu dialog via callback dengan path baru.
  Future<void> _pilihLogo(
    BuildContext dialogContext,
    StateSetter setDialogState,
    void Function(String path) onPicked,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: dialogContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker()
        .pickImage(source: source, imageQuality: 90, maxWidth: 1024);
    if (file == null) return;

    final path = await FotoHelper.simpanLogo(File(file.path));
    onPicked(path);
    setDialogState(() {});
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _MenuItem(this.label, this.icon, this.onTap);
}

class _JudulBagian extends StatelessWidget {
  final String judul;

  const _JudulBagian(this.judul);

  @override
  Widget build(BuildContext context) {
    return Text(
      judul,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
    );
  }
}

// Tampilkan logo toko di header Beranda (fallback ke asset bila belum ada
// logo kustom atau file-nya hilang).
class _LogoBeranda extends StatelessWidget {
  final String? logoPath;
  final double size;

  const _LogoBeranda({required this.logoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    if (logoPath != null && File(logoPath!).existsSync()) {
      return Image.file(File(logoPath!), width: size, height: size);
    }
    return Image.asset('assets/images/logo.png', width: size, height: size);
  }
}

class _RingkasanHariIni extends StatelessWidget {
  final List<Penjualan> penjualanList;

  const _RingkasanHariIni({required this.penjualanList});

  // Nama hari/bulan manual, sama dengan pola yang dipakai penjualan_view.dart,
  // supaya konsisten tanpa menambah dependensi intl.
  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];
  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final transaksiHariIni = penjualanList
        .where(
          (p) => p.tanggal.isAfter(hariIni.subtract(const Duration(days: 1))),
        )
        .toList();

    final totalHariIni =
        transaksiHariIni.fold<double>(0.0, (t, p) => t + p.totalHarga);
    final jumlahTransaksi = transaksiHariIni.length;
    final jumlahProduk = transaksiHariIni.fold<int>(
      0,
      (t, p) => t + p.daftarProduk.fold<int>(0, (s, item) => s + item.jumlah),
    );

    final tanggalLabel =
        '${_namaHari[sekarang.weekday - 1]}, ${sekarang.day} ${_namaBulan[sekarang.month - 1]} ${sekarang.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penjualan hari ini',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            tanggalLabel,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Rp${FormatHelper.rupiah(totalHariIni)}',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatistikKecil(angka: '$jumlahTransaksi', label: 'transaksi'),
              const SizedBox(width: 24),
              _StatistikKecil(angka: '$jumlahProduk', label: 'produk terjual'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatistikKecil extends StatelessWidget {
  final String angka;
  final String label;

  const _StatistikKecil({required this.angka, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(angka,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}

// Kartu berisi keranjang yang masih berjalan, hanya muncul kalau ada isi. Tujuannya
// menghemat langkah kasir: dari beranda langsung lanjut ke pembayaran tanpa berpindah tab.
class _KeranjangBerjalan extends StatelessWidget {
  final List<Keranjang> keranjangList;
  final double totalHarga;
  final VoidCallback onLanjutkan;

  const _KeranjangBerjalan({
    required this.keranjangList,
    required this.totalHarga,
    required this.onLanjutkan,
  });

  @override
  Widget build(BuildContext context) {
    if (keranjangList.isEmpty) return const SizedBox.shrink();
    final totalItem = keranjangList.fold<int>(0, (t, item) => t + item.jumlah);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_cart_outlined,
                color: Colors.amber.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalItem item di keranjang',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Rp${FormatHelper.rupiah(totalHarga)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onLanjutkan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }
}

// Menu akses cepat ke empat tab lain. Dibuat 2 baris x 2 kolom: ikon + label datar tanpa
// latar berwarna, supaya mata kasir langsung menangkap teksnya.
class _GridMenu extends StatelessWidget {
  final List<_MenuItem> menuItems;

  const _GridMenu({required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < menuItems.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: _menuTile(menuItems[i])),
              const SizedBox(width: 12),
              if (i + 1 < menuItems.length)
                Expanded(child: _menuTile(menuItems[i + 1])),
            ],
          ),
          if (i + 2 < menuItems.length) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _menuTile(_MenuItem item) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: Colors.grey.shade800, size: 24),
              const SizedBox(height: 12),
              Text(item.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// Daftar produk yang stoknya tinggal sedikit, paling menipis di atas. Hanya muncul kalau ada
// yang benar-benar perlu perhatian, supaya beranda tidak selalu berubah-ubah bentuknya.
class _StokMenipis extends StatelessWidget {
  final List<Produk> produkList;
  final VoidCallback onLihatProduk;

  const _StokMenipis({required this.produkList, required this.onLihatProduk});

  @override
  Widget build(BuildContext context) {
    // Produk dengan stok yang masih ada (bukan habis total), terendah dulu.
    final menipis = produkList.where((p) => p.stok > 0 && p.stok <= 5).toList()
      ..sort((a, b) => a.stok.compareTo(b.stok));
    final itemShown = menipis.take(3).toList();

    if (itemShown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _JudulBagian('Stok menipis'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final p in itemShown)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.namaProduk,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'sisa ${p.stok}',
                        style: TextStyle(
                          color: p.stok <= 3
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (menipis.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: onLihatProduk,
                    child: Text('Lihat semua (${menipis.length} produk)'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
