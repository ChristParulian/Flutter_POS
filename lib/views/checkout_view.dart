import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/penjualan_controller.dart';
import '../controllers/produk_controller.dart';
import '../helpers/database_helper.dart';
import '../helpers/format_helper.dart';
import '../helpers/struk_helper.dart';
import '../models/keranjang.dart';
import '../widgets/numpad.dart';

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
      keranjangCheckout = Provider.of<KeranjangController>(context, listen: false).keranjangList;
    }
  }

  @override
  void dispose() {
    bayarController.dispose();
    super.dispose();
  }

  double get total => keranjangCheckout.fold<double>(0.0, (t, item) => t + item.totalHarga);

  // Batas stok saat menambah jumlah lewat stepper di sini - mengintip stok produk terkini
  // supaya tidak bisa dinaikkan melebihi yang tersedia (baru gagal saat "Selesaikan
  // Pembayaran" ditekan itu terlambat, lebih baik dicegah sejak stepper-nya).
  int? _stokProduk(int produkId) {
    final produkController = Provider.of<ProdukController>(context, listen: false);
    for (final p in produkController.produkList) {
      if (p.id == produkId) return p.stok;
    }
    return null;
  }

  void _ubahJumlah(Keranjang item, int jumlahBaru) {
    if (jumlahBaru < 1) return;
    final stok = _stokProduk(item.id);
    if (stok != null && jumlahBaru > stok) return;

    final keranjangController = Provider.of<KeranjangController>(context, listen: false);
    keranjangController.ubahJumlah(item.id, jumlahBaru);
    setState(() {});
  }

  void _hapusItem(Keranjang item) {
    final keranjangController = Provider.of<KeranjangController>(context, listen: false);
    keranjangController.hapusDariKeranjang(item.id);
    setState(() {
      keranjangCheckout = keranjangCheckout.where((e) => e.id != item.id).toList();
      final bayar = double.tryParse(bayarController.text.trim()) ?? 0.0;
      kembalian = bayar - total;
    });
  }

  Future<void> _prosesCheckout() async {
    final penjualanController = Provider.of<PenjualanController>(context, listen: false);
    final keranjangController = Provider.of<KeranjangController>(context, listen: false);
    final bayar = double.tryParse(bayarController.text.trim()) ?? 0.0;

    setState(() => _diproses = true);
    try {
      final penjualanTersimpan = await penjualanController.simpanPenjualan(keranjangCheckout, total, bayar, kembalian);
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
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _diproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: keranjangCheckout.isEmpty
          ? Center(child: Text('Tidak ada item untuk dibayar.', style: TextStyle(color: Colors.grey.shade600)))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: keranjangCheckout.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = keranjangCheckout[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.namaProduk,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    tooltip: 'Hapus item',
                                    onPressed: () => _hapusItem(item),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _StepperButton(
                                        icon: Icons.remove,
                                        onTap: item.jumlah > 1 ? () => _ubahJumlah(item, item.jumlah - 1) : null,
                                      ),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '${item.jumlah}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      _StepperButton(
                                        icon: Icons.add,
                                        onTap: () => _ubahJumlah(item, item.jumlah + 1),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rp${FormatHelper.rupiah(item.totalHarga)}',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            Text('Rp${FormatHelper.rupiah(total)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.amber.shade800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Tampilan jumlah bayar: teks biasa (bukan TextField readonly) supaya
                        // tidak ada risiko keyboard/menu konteks muncul tak sengaja - input
                        // murni lewat Numpad di bawah.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Rp ${FormatHelper.rupiah(int.tryParse(bayarController.text) ?? 0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Rp${FormatHelper.rupiah(kembalian < 0 ? 0 : kembalian)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                          onPressed: (!_diproses && kembalian >= 0 && bayarController.text.isNotEmpty) ? _prosesCheckout : null,
                          icon: _diproses
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_diproses ? 'Memproses...' : 'Selesaikan Pembayaran'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
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
      icon: Icon(icon, size: 16, color: aktif ? Colors.amber.shade800 : Colors.grey.shade400),
      onPressed: onTap,
    );
  }
}
