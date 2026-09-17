import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'controllers/produk_controller.dart';
import 'controllers/kategori_controller.dart';
import 'controllers/keranjang_controller.dart';
import 'controllers/penjualan_controller.dart';
import 'controllers/pengaturan_controller.dart';
import 'views/beranda_view.dart';
import 'views/kategori_view.dart';
import 'views/produk_view.dart';
import 'views/keranjang_view.dart';
import 'views/checkout_view.dart';
import 'views/penjualan_view.dart';

// Aksen amber/emas dipertahankan sebagai identitas merek (logo, splash),
// tapi hanya dipakai untuk aksi utama, bukan lagi latar penuh-layar. Lihat DESIGN.md.
const kAmber = Colors.amber;
const kBackground = Color(0xFFF7F7F8);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          create: (context) => PenjualanController()..muatPenjualan(),
        ),
        ChangeNotifierProvider<PengaturanController>(
          create: (context) => PengaturanController()..muatPengaturan(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Sengaja pakai `home:` (bukan `initialRoute: '/splash'`): kalau initialRoute memakai
        // nama rute selain '/', Flutter otomatis menyisipkan '/' ke stack sebelum mendorong
        // rute tersebut, sehingga setelah splash pindah ke '/' stack jadi dobel dan memunculkan
        // tombol back yang tidak seharusnya ada di halaman utama.
        home: const SplashScreen(),
        theme: _buildTheme(),
        // '/' sengaja tidak didaftarkan di sini: Flutter melarang kombinasi `home:` dengan
        // entri routes['/'] (redundan/konflik). Splash berpindah ke HomeShell lewat
        // MaterialPageRoute langsung, bukan nama rute.
        routes: {
          '/checkout': (context) => const CheckoutView(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kAmber.shade700,
      primary: kAmber.shade700,
      surface: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Inter dipilih tetap demi keterbacaan (bukan gaya): bentuk digitnya lebih mudah
      // dibedakan daripada Roboto untuk baca cepat harga/stok. Lihat DESIGN.md.
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: kBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kAmber.shade700, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAmber.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: kAmber.shade700,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kAmber.shade700,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        selectedColor: kAmber.shade700,
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Latar penuh warna brand di sini dibiarkan sebagai satu-satunya pengecualian:
    // splash hanya tampil sekali sebentar sebagai momen pengenalan merek, bukan permukaan kerja berulang.
    return Scaffold(
      backgroundColor: kAmber.shade700,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                'Smart Toko',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shell utama aplikasi: Beranda sebagai tab pertama (menyapa + menu cepat), lalu bottom
// navigation tetap supaya berpindah antar Kategori, Produk, Keranjang, dan Penjualan
// tidak perlu bolak-balik ke Beranda.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Indeks tab Beranda di bottom navigation. Semua back/navigasi "naik tingkat" berujung ke
  // tab ini - lihat _handleBack.
  static const int _berandaIndex = 0;

  int _index = 0;

  void _pindahTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<bool> _konfirmasiKeluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Aplikasi'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return keluar ?? false;
  }

  // Tombol back berperilaku sebagai "naik satu tingkat", bukan "mundur satu langkah":
  // di tab mana pun selain Beranda, back mengembalikan ke Beranda; di Beranda sendiri,
  // back baru berarti keluar dari aplikasi - dan itu pun selalu lewat konfirmasi dulu
  // supaya kasir tidak kehilangan posisinya karena tombol yang tersenggol.
  Future<void> _handleBack() async {
    if (_index != _berandaIndex) {
      setState(() => _index = _berandaIndex);
      return;
    }
    if (await _konfirmasiKeluar()) {
      SystemNavigator.pop();
    }
  }

  // Dibangun ulang tiap build() (bukan `late final` sekali saja) supaya KeranjangView bisa
  // menerima flag `active` yang reaktif - dipakai untuk tahu kapan boleh menahan fokus field
  // scan barcode fisik. Ini aman untuk state tab lain: Flutter menjaga State berdasarkan
  // tipe widget + posisi di IndexedStack, bukan identitas instance widget-nya.
  List<Widget> _buildTabs() => [
        BerandaView(onNavigateToTab: _pindahTab),
        const KategoriView(),
        const ProdukView(),
        KeranjangView(active: _index == 3),
        const PenjualanView(),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _buildTabs()),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: _pindahTab,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Kategori'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined), activeIcon: Icon(Icons.shopping_basket), label: 'Produk'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Keranjang'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Penjualan'),
          ],
        ),
      ),
    );
  }
}
