import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/penjualan_controller.dart';
import '../controllers/produk_controller.dart';
import '../helpers/database_helper.dart';
import '../helpers/format_helper.dart';
import '../helpers/struk_helper.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';
import '../widgets/numpad.dart';
import 'barcode_scanner_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final TextEditingController bayarController = TextEditingController();
  double kembalian = 0.0;
  List<Keranjang> keranjangCheckout = [];
  bool _diproses = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List<Keranjang>) {
      keranjangCheckout = args;
    } else {
      keranjangCheckout =
          Provider.of<KeranjangController>(context, listen: false)
              .keranjangList;
    }
  }

  @override
  void dispose() {
    bayarController.dispose();
    super.dispose();
  }

  double get total =>
      keranjangCheckout.fold<double>(0.0, (t, item) => t + item.totalHarga);

  // Batas stok saat menambah jumlah lewat stepper di sini - mengintip stok produk terkini
  // supaya tidak bisa dinaikkan melebihi yang tersedia (baru gagal saat "Selesaikan
  // Pembayaran" ditekan itu terlambat, lebih baik dicegah sejak stepper-nya).
  int? _stokProduk(int produkId) {
    final produkController =
        Provider.of<ProdukController>(context, listen: false);
    for (final p in produkController.produkList) {
      if (p.id == produkId) return p.stok;
    }
    return null;
  }

  void _ubahJumlah(Keranjang item, int jumlahBaru) {
    if (jumlahBaru < 1) return;
    final stok = _stokProduk(item.id);
    if (stok != null && jumlahBaru > stok) return;

    final keranjangController =
        Provider.of<KeranjangController>(context, listen: false);
    keranjangController.ubahJumlah(item.id, jumlahBaru);
    setState(() {});
  }

  void _hapusItem(Keranjang item) {
    final keranjangController =
        Provider.of<KeranjangController>(context, listen: false);
    keranjangController.hapusDariKeranjang(item.id);
    setState(() {
      keranjangCheckout =
          keranjangCheckout.where((e) => e.id != item.id).toList();
      final bayar = double.tryParse(bayarController.text.trim()) ?? 0.0;
      kembalian = bayar - total;
    });
  }

  // Mengubah jumlah item yang sedang dibayar. Dipakai bersama oleh stepper +/- di kartu item
  // dan tombol aksi cepat, supaya batas stok selalu diperiksa di satu tempat.
  void _isiUangPas() {
    setState(() {
      bayarController.text = total.round().toString();
      kembalian = 0;
    });
  }

  // Nominal yang diketik langsung menggantikan isi field (bukan ditambahkan), karena tombol
  // ini dimaksudkan untuk melompat ke angka bulat, bukan menambah digit ke angka sebelumnya.
  void _setNominalCepat(int nominal) {
    setState(() {
      bayarController.text = nominal.toString();
      kembalian = nominal - total;
    });
  }

  // Dua nominal pembulatan ke atas dari total (mis. 47.500 -> 50.000 dan 100.000) supaya
  // pilihan yang ditawarkan mengikuti nilai belanja, bukan angka mati yang sering meleset.
  List<int> _nominalPembulatan() {
    final bawah = total.ceil();
    final ke50rb = ((bawah + 49999) ~/ 50000) * 50000;
    final ke100rb = ((bawah + 99999) ~/ 100000) * 100000;
    return {
      if (ke50rb > bawah) ke50rb,
      if (ke100rb > ke50rb) ke100rb,
    }.toList();
  }

  // Scan barcode di tengah checkout berguna saat kasir lupa satu barang setelah total dihitung:
  // dibanding balik ke halaman sebelumnya, cukup pindai di sini, produk otomatis masuk ke
  // keranjang (dan ke daftar yang sedang dibayar), lalu user selesai tanpa pindah layar.
  Future<void> _bukaScannerKamera() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerView(title: 'Pindai Barcode')),
    );
    if (!mounted || kode == null || kode.isEmpty) return;

    final produkController =
        Provider.of<ProdukController>(context, listen: false);
    final keranjangController =
        Provider.of<KeranjangController>(context, listen: false);

    Produk? produk;
    for (final p in produkController.produkList) {
      if (p.barcode == kode) {
        produk = p;
        break;
      }
    }

    if (produk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Barcode "$kode" tidak ditemukan'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final sisaStok =
        produk.stok - keranjangController.jumlahDiKeranjang(produk.id!);
    if (sisaStok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Stok "${produk.namaProduk}" habis'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    keranjangController.tambahKeKeranjang(
      Keranjang(
          id: produk.id!,
          namaProduk: produk.namaProduk,
          harga: produk.harga,
          jumlah: 1),
    );
    setState(() {
      keranjangCheckout = keranjangController.keranjangList;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('"${produk.namaProduk}" ditambahkan'),
          duration: const Duration(milliseconds: 1200)),
    );
  }

  Future<void> _prosesCheckout() async {
    final penjualanController =
        Provider.of<PenjualanController>(context, listen: false);
    final keranjangController =
        Provider.of<KeranjangController>(context, listen: false);
    final bayar = double.tryParse(bayarController.text.trim()) ?? 0.0;

    setState(() => _diproses = true);
    try {
      final penjualanTersimpan = await penjualanController.simpanPenjualan(
          keranjangCheckout, total, bayar, kembalian);
      for (final item in keranjangCheckout) {
        keranjangController.hapusDariKeranjang(item.id);
      }
      if (!mounted) return;

      // Struk langsung dicetak begitu transaksi tersimpan. Gagal cetak (mis. tidak ada
      // printer/dibatalkan) tidak membatalkan transaksi yang sudah tersimpan - kasir masih
      // bisa cetak ulang dari Riwayat Penjualan.
      try {
        await StrukHelper.cetakStruk(penjualanTersimpan);
      } catch (_) {
        // sengaja diabaikan, lihat catatan di atas
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } on StokTidakCukupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _diproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            tooltip: 'Pindai Barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _bukaScannerKamera,
          ),
        ],
      ),
      body: keranjangCheckout.isEmpty
          ? Center(
              child: Text('Tidak ada item untuk dibayar.',
                  style: TextStyle(color: Colors.grey.shade600)))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: keranjangCheckout.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = keranjangCheckout[index];
                      // Find produk for foto and stok info
                      final produkController =
                          Provider.of<ProdukController>(context, listen: false);
                      Produk? produk;
                      for (final p in produkController.produkList) {
                        if (p.id == item.id) {
                          produk = p;
                          break;
                        }
                      }
                      final habis = produk == null ? false : produk.stok <= 0;
                      final sisaStok = produk == null ? 0 : produk.stok;

                      // Kartu item dibuat ringkas tanpa foto: di halaman checkout kasir
                      // butuh informasi padat (nama, stok, jumlah, harga) supaya daftar
                      // item yang panjang tetap muat satu layar.
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaProduk,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: habis
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            habis
                                                ? 'Stok habis'
                                                : 'Stok $sisaStok',
                                            style: TextStyle(
                                              color: habis
                                                  ? Colors.red.shade700
                                                  : Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp${FormatHelper.rupiah(item.totalHarga)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber.shade800),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _StepperButton(
                                        icon: Icons.remove,
                                        onTap: item.jumlah > 1
                                            ? () => _ubahJumlah(
                                                item, item.jumlah - 1)
                                            : null,
                                      ),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '${item.jumlah}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      _StepperButton(
                                        icon: Icons.add,
                                        onTap: () =>
                                            _ubahJumlah(item, item.jumlah + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  tooltip: 'Hapus item',
                                  onPressed: () => _hapusItem(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade200))),
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            Text('Rp${FormatHelper.rupiah(total)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.amber.shade800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Tampilan jumlah bayar: teks biasa (bukan TextField readonly) supaya
                        // tidak ada risiko keyboard/menu konteks muncul tak sengaja - input
                        // murni lewat Numpad di bawah.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Rp ${FormatHelper.rupiah(int.tryParse(bayarController.text) ?? 0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                                'Rp${FormatHelper.rupiah(kembalian < 0 ? 0 : kembalian)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Nominal cepat: uang pas (nominal paling sering dipakai) lalu kelipatan
                        // bulat di atas total, supaya kasir tidak perlu mengetik digit per digit.
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isiUangPas,
                                child: const Text('Uang Pas'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ..._nominalPembulatan().map(
                              (nominal) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: OutlinedButton(
                                    onPressed: () => _setNominalCepat(nominal),
                                    child: Text(FormatHelper.ringkas(nominal)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Numpad(
                          value: bayarController.text,
                          onChanged: (newValue) {
                            setState(() {
                              bayarController.text = newValue;
                              final bayar = double.tryParse(newValue) ?? 0.0;
                              kembalian = bayar - total;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: (!_diproses &&
                                  kembalian >= 0 &&
                                  bayarController.text.isNotEmpty)
                              ? _prosesCheckout
                              : null,
                          icon: _diproses
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_diproses
                              ? 'Memproses...'
                              : 'Selesaikan Pembayaran'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return IconButton(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: aktif ? Colors.amber.shade50 : Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon,
          size: 16,
          color: aktif ? Colors.amber.shade800 : Colors.grey.shade400),
      onPressed: onTap,
    );
  }
}
