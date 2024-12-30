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
  TextEditingController _searchController = TextEditingController();
  List<Penjualan> filteredPenjualan = [];

  @override
  void initState() {
    super.initState();
    var penjualanController = Provider.of<PenjualanController>(context, listen: false);
    penjualanController.muatPenjualanDariFile();
    filteredPenjualan = penjualanController.daftarPenjualan;

    // Mengurutkan berdasarkan tanggal dan waktu
    filteredPenjualan.sort((a, b) {
      // Pastikan 'formattedTanggal' berisi format yang valid, misalnya: 'yyyy-MM-dd HH:mm:ss'
      DateTime dateA = DateTime.parse(a.formattedTanggal);
      DateTime dateB = DateTime.parse(b.formattedTanggal);
      return dateB.compareTo(dateA); // Urutkan berdasarkan tanggal dan waktu terbaru
    });
  }


  @override
  Widget build(BuildContext context) {
    var penjualanController = Provider.of<PenjualanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                _filterPenjualan(query, penjualanController);
              },
              decoration: InputDecoration(
                labelText: 'Cari Penjualan',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredPenjualan.isEmpty
                ? Center(
              child: Text(
                'Belum ada penjualan.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            )
                : ListView.builder(
              itemCount: filteredPenjualan.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final penjualan = filteredPenjualan[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Tanggal: ${penjualan.formattedTanggal}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Harga: Rp${penjualan.totalHarga.toStringAsFixed(penjualan.totalHarga == penjualan.totalHarga.toInt() ? 0 : 2)}'),
                        Text('Jumlah Dibayar: Rp${penjualan.jumlahDibayar.toStringAsFixed(penjualan.jumlahDibayar == penjualan.jumlahDibayar.toInt() ? 0 : 2)}'),
                        Text('Kembalian: Rp${penjualan.kembalian.toStringAsFixed(penjualan.kembalian == penjualan.kembalian.toInt() ? 0 : 2)}'),
                      ],
                    ),
                    iconColor: Colors.amber,
                    textColor: Colors.black87,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Produk:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Divider(color: Colors.amber.shade300),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: penjualan.daftarProduk.length,
                              itemBuilder: (context, itemIndex) {
                                final produk = penjualan.daftarProduk[itemIndex];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(produk.namaProduk),
                                  subtitle: Text('Qty: ${produk.jumlah} - Rp${produk.totalHarga.toStringAsFixed(produk.totalHarga == produk.totalHarga.toInt() ? 0 : 2)}'),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
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
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _printPenjualan(penjualan);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Cetak', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _filterPenjualan(String query, PenjualanController penjualanController) {
    if (query.isEmpty) {
      setState(() {
        filteredPenjualan = penjualanController.daftarPenjualan;
      });
    } else {
      setState(() {
        filteredPenjualan = penjualanController.daftarPenjualan.where((penjualan) {
          return penjualan.formattedTanggal.toLowerCase().contains(query.toLowerCase()) ||
              penjualan.daftarProduk.any((produk) => produk.namaProduk.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      });
    }
  }

  void _printPenjualan(Penjualan penjualan) async {
    final pdf = pw.Document();

    // Ukuran kertas thermal: 58mm (2.28 inches)
    final pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text('Struk Belanja', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Tanggal: ${penjualan.formattedTanggal}', style: pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              // Detail Produk
              pw.Text('Detail Produk:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ...penjualan.daftarProduk.map(
                    (produk) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(produk.namaProduk, style: pw.TextStyle(fontSize: 7)),
                    pw.Text('Qty: ${produk.jumlah}', style: pw.TextStyle(fontSize: 7)),
                    pw.Text('Rp${produk.totalHarga == produk.totalHarga.toInt() ? produk.totalHarga.toStringAsFixed(0) : produk.totalHarga.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ).toList(),
              pw.Divider(),
              // Informasi Penjualan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${penjualan.totalHarga == penjualan.totalHarga.toInt() ? penjualan.totalHarga.toStringAsFixed(0) : penjualan.totalHarga.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dibayar:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${penjualan.jumlahDibayar == penjualan.jumlahDibayar.toInt() ? penjualan.jumlahDibayar.toStringAsFixed(0) : penjualan.jumlahDibayar.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${penjualan.kembalian == penjualan.kembalian.toInt() ? penjualan.kembalian.toStringAsFixed(0) : penjualan.kembalian.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
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
