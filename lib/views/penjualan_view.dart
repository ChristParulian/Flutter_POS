import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Memuat penjualan dari file saat PenjualanView pertama kali dibuka
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
                          // Hapus penjualan dari daftar
                          penjualanController.daftarPenjualan.removeAt(index);
                          penjualanController.simpanPenjualanKeFile(); // Simpan perubahan ke file
                          penjualanController.notifyListeners();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Penjualan berhasil dihapus'),
                            ),
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
}
