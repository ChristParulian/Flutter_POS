import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'format_helper.dart';
import 'database_helper.dart';
import '../models/penjualan.dart';

// Cetak struk dipakai bersama dari dua tempat: Riwayat Penjualan (cetak ulang manual) dan
// Checkout (cetak otomatis begitu transaksi tersimpan) - supaya tidak duplikat logika PDF.
// Nama & alamat toko diambil dari tabel pengaturan setiap kali dicetak, jadi header struk
// selalu mengikuti identitas terakhir yang disimpan di halaman Beranda.
class StrukHelper {
  static Future<void> cetakStruk(Penjualan penjualan) async {
    final pdf = pw.Document();
    const pageFormat =
        PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5);
    final bytes = await rootBundle.load('assets/images/logo.png');
    final image = pw.MemoryImage(bytes.buffer.asUint8List());
    final pengaturan = await DatabaseHelper.getPengaturan();
    final namaToko = pengaturan?.namaToko ?? 'Smart Toko';
    final alamatToko = pengaturan?.alamatToko.trim() ?? '';

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
                  pw.Text(namaToko,
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (alamatToko.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  alamatToko,
                  textAlign: pw.TextAlign.center,
                  style:
                      const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Text('Struk Belanja',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Tanggal: ${penjualan.formattedTanggal}',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(),
              pw.Text('Detail Produk:',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ...penjualan.daftarProduk.map(
                (produk) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(produk.namaProduk,
                        style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Qty: ${produk.jumlah}',
                        style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Rp${rupiah(produk.totalHarga)}',
                        style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${rupiah(penjualan.totalHarga)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dibayar:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${rupiah(penjualan.jumlahDibayar)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Rp${rupiah(penjualan.kembalian)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
