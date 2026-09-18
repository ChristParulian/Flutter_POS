import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'format_helper.dart';
import 'database_helper.dart';
import '../models/penjualan.dart';

/// Custom dashed line widget for PDF using Row of containers
class DashedLine extends pw.StatelessWidget {
  final double dashLength;
  final double spaceLength;
  final double lineWidth;
  final PdfColor color;

  DashedLine({
    this.dashLength = 4,
    this.spaceLength = 4,
    this.lineWidth = 1,
    this.color = PdfColors.grey600,
  });

  @override
  pw.Widget build(pw.Context context) {
    // Use a fixed width approach for the receipt (58mm)
    const pageWidth = 58 * 2.83465; // 58mm in points (1mm = 2.83465pt) // ignore: prefer_const_declarations
    final availableWidth = pageWidth - 10; // minus margins
    final dashCount = (availableWidth / (dashLength + spaceLength)).floor();
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: List.generate(dashCount, (index) {
        return pw.Container(
          width: dashLength,
          height: lineWidth,
          color: color,
          margin: pw.EdgeInsets.only(right: spaceLength),
        );
      }),
    );
  }
}

// Cetak struk dipakai bersama dari dua tempat: Riwayat Penjualan (cetak ulang manual) dan
// Checkout (cetak otomatis begitu transaksi tersimpan) - supaya tidak duplikat logika PDF.
// Nama & alamat toko diambil dari tabel pengaturan setiap kali dicetak, jadi header struk
// selalu mengikuti identitas terakhir yang disimpan di halaman Beranda.
class StrukHelper {
  static Future<void> cetakStruk(Penjualan penjualan) async {
    final pdf = pw.Document();
    const pageFormat =
        PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5);
    final pengaturan = await DatabaseHelper.getPengaturan();
    final namaToko = pengaturan?.namaToko ?? 'Smart Toko';
    final alamatToko = pengaturan?.alamatToko.trim() ?? '';

    // Logo di header struk mengikuti logo toko yang disimpan di Beranda. Kalau belum ada
    // logo kustom (atau file-nya hilang) kembali ke logo bawaan aplikasi.
    late final pw.MemoryImage image;
    final logoPath = pengaturan?.logoPath;
    if (logoPath != null && File(logoPath).existsSync()) {
      final bytes = await File(logoPath).readAsBytes();
      image = pw.MemoryImage(bytes);
    } else {
      final bytes = await rootBundle.load('assets/images/logo.png');
      image = pw.MemoryImage(bytes.buffer.asUint8List());
    }

    String rupiah(double v) => FormatHelper.rupiah(v);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo di atas nama toko
              pw.Image(image, width: 32, height: 32),
              pw.SizedBox(height: 5),
              // Nama toko
              pw.Text(namaToko,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              // Alamat toko (jika ada)
              if (alamatToko.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  alamatToko,
                  textAlign: pw.TextAlign.center,
                  style:
                      const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 5),
              // Pembatas garis putus-putus untuk tanggal/waktu
              DashedLine(
                dashLength: 3,
                spaceLength: 3,
                lineWidth: 1,
                color: PdfColors.grey600,
              ),
              pw.SizedBox(height: 5),
              // Tanggal & waktu transaksi (tanpa label "Tanggal:")
              pw.Text(
                penjualan.formattedTanggalWaktu,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 5),
              // Pembatas garis putus-putus
              DashedLine(
                dashLength: 3,
                spaceLength: 3,
                lineWidth: 1,
                color: PdfColors.grey600,
              ),
              pw.SizedBox(height: 5),
              // Detail Produk
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Detail Produk:',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
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
              pw.SizedBox(height: 8),
              DashedLine(
                dashLength: 3,
                spaceLength: 3,
                lineWidth: 1,
                color: PdfColors.grey600,
              ),
              pw.SizedBox(height: 8),
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
              pw.SizedBox(height: 10),
              DashedLine(
                dashLength: 3,
                spaceLength: 3,
                lineWidth: 1,
                color: PdfColors.grey600,
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Terima kasih atas kunjungan Anda',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text('Selamat berbelanja kembali',
                    style: const pw.TextStyle(fontSize: 7)),
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
