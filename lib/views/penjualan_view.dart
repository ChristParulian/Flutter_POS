import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/penjualan_controller.dart';
import '../models/penjualan.dart';

class PenjualanView extends StatefulWidget {
  const PenjualanView({super.key});

  @override
  State<PenjualanView> createState() => _PenjualanViewState();
}

class _PenjualanViewState extends State<PenjualanView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Provider.of<PenjualanController>(context, listen: false).muatPenjualan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final penjualanController = context.watch<PenjualanController>();

    final filtered = _searchQuery.isEmpty
        ? penjualanController.daftarPenjualan
        : penjualanController.daftarPenjualan.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.formattedTanggal.toLowerCase().contains(query) ||
                p.daftarProduk.any((item) => item.namaProduk.toLowerCase().contains(query));
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penjualan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari tanggal atau nama produk...',
              ),
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
          Expanded(
            child: penjualanController.isLoading && penjualanController.daftarPenjualan.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          penjualanController.daftarPenjualan.isEmpty ? 'Belum ada transaksi.' : 'Tidak ada transaksi yang cocok.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final penjualan = filtered[index];
                          return Card(
                            child: ListTile(
                              title: Text(penjualan.formattedTanggal, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${penjualan.daftarProduk.length} produk'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Rp${penjualan.totalHarga.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    onPressed: () => _printPenjualan(penjualan),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _hapusPenjualan(context, penjualanController, penjualan),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusPenjualan(BuildContext context, PenjualanController controller, Penjualan penjualan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus transaksi tanggal ${penjualan.formattedTanggal}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await controller.hapusPenjualan(penjualan);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _printPenjualan(Penjualan penjualan) async {
    try {
      final pdf = pw.Document();
      final pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5);
      final bytes = await rootBundle.load('assets/images/logo.png');
      final image = pw.MemoryImage(bytes.buffer.asUint8List());

      String rupiah(double v) => v == v.toInt() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(image, width: 24, height: 24),
                    pw.SizedBox(width: 5),
                    pw.Text('Smart Toko', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('Struk Belanja', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text('Tanggal: ${penjualan.formattedTanggal}', style: pw.TextStyle(fontSize: 8)),
                pw.Divider(),
                pw.Text('Detail Produk:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ...penjualan.daftarProduk.map(
                  (produk) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(produk.namaProduk, style: pw.TextStyle(fontSize: 7)),
                      pw.Text('Qty: ${produk.jumlah}', style: pw.TextStyle(fontSize: 7)),
                      pw.Text('Rp${rupiah(produk.totalHarga)}', style: pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total:', style: pw.TextStyle(fontSize: 8)),
                    pw.Text('Rp${rupiah(penjualan.totalHarga)}', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Dibayar:', style: pw.TextStyle(fontSize: 8)),
                    pw.Text('Rp${rupiah(penjualan.jumlahDibayar)}', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali:', style: pw.TextStyle(fontSize: 8)),
                    pw.Text('Rp${rupiah(penjualan.kembalian)}', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak: $e')));
    }
  }
}
