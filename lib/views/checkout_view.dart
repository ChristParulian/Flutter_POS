import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/penjualan_controller.dart';
import '../helpers/database_helper.dart';
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

  Future<void> _prosesCheckout() async {
    final penjualanController = Provider.of<PenjualanController>(context, listen: false);
    final keranjangController = Provider.of<KeranjangController>(context, listen: false);
    final bayar = double.tryParse(bayarController.text.trim()) ?? 0.0;

    setState(() => _diproses = true);
    try {
      await penjualanController.simpanPenjualan(keranjangCheckout, total, bayar, kembalian);
      for (final item in keranjangCheckout) {
        keranjangController.hapusDariKeranjang(item.id);
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
                        child: ListTile(
                          title: Text(item.namaProduk, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${item.jumlah} x Rp${item.harga.toStringAsFixed(0)}'),
                          trailing: Text('Rp${item.totalHarga.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
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
                            Text('Rp${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.amber.shade800)),
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
                            'Rp ${bayarController.text.isEmpty ? "0" : bayarController.text}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Rp${kembalian < 0 ? 0 : kembalian.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
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
