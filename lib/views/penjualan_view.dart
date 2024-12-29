import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/penjualan_controller.dart';
import '../models/penjualan.dart';

class PenjualanView extends StatefulWidget {
  @override
  _PenjualanViewState createState() => _PenjualanViewState();
}

class _PenjualanViewState extends State<PenjualanView> {
  @override
  void initState() {
    super.initState();
    var penjualanController = Provider.of<PenjualanController>(context, listen: false);
    penjualanController.muatPenjualanDariFile();
  }

  @override
  Widget build(BuildContext context) {
    var penjualanController = Provider.of<PenjualanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Penjualan'),
        backgroundColor: Colors.teal,
      ),
      body: penjualanController.daftarPenjualan.isEmpty
          ? Center(child: Text('Belum ada penjualan.'))
          : ListView.builder(
        itemCount: penjualanController.daftarPenjualan.length,
        itemBuilder: (context, index) {
          final penjualan = penjualanController.daftarPenjualan[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ExpansionTile(
              title: Text('Tanggal: ${penjualan.formattedTanggal}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Harga: Rp${penjualan.totalHarga.toStringAsFixed(2)}'),
                  Text('Jumlah Dibayar: Rp${penjualan.jumlahDibayar.toStringAsFixed(2)}'),
                  Text('Kembalian: Rp${penjualan.kembalian.toStringAsFixed(2)}'),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Produk:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: penjualan.daftarProduk.length,
                        itemBuilder: (context, itemIndex) {
                          final produk = penjualan.daftarProduk[itemIndex];
                          return ListTile(
                            title: Text(produk.namaProduk),
                            subtitle: Text(
                              'Qty: ${produk.jumlah} - Rp${produk.totalHarga.toStringAsFixed(2)}',
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          penjualanController.daftarPenjualan.removeAt(index);
                          penjualanController.simpanPenjualanKeFile();
                          penjualanController.notifyListeners();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Penjualan berhasil dihapus')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Hapus Penjualan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _printPenjualan(penjualan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Cetak Penjualan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _printPenjualan(Penjualan penjualan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text('Laporan Penjualan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Tanggal Penjualan: ${penjualan.formattedTanggal}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Detail Produk (Di atas)
              pw.Text('Detail Produk:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...penjualan.daftarProduk.map(
                    (produk) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(produk.namaProduk, style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Qty: ${produk.jumlah}', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Rp${produk.totalHarga.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ).toList(),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Informasi Penjualan (Setelah Detail Produk)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Harga:', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rp${penjualan.totalHarga.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Jumlah Dibayar:', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rp${penjualan.jumlahDibayar.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembalian:', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rp${penjualan.kembalian.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // Print or save the PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
