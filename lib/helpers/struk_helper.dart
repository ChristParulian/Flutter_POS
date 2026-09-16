import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'format_helper.dart';
import '../models/penjualan.dart';

// Cetak struk dipakai bersama dari dua tempat: Riwayat Penjualan (cetak ulang manual) dan
// Checkout (cetak otomatis begitu transaksi tersimpan) - supaya tidak duplikat logika PDF.
class StrukHelper {
  static Future<void> cetakStruk(Penjualan penjualan) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5);
    final bytes = await rootBundle.load('assets/images/logo.png');
    final image = pw.MemoryImage(bytes.buffer.asUint8List());

    String rupiah(double v) => FormatHelper.rupiah(v);

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
  }
}
