import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/penjualan_controller.dart';

class CheckoutView extends StatefulWidget {
  @override
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  TextEditingController bayarController = TextEditingController();
  double kembalian = 0.0;

  @override
  Widget build(BuildContext context) {
    var keranjangController = Provider.of<KeranjangController>(context);
    var penjualanController = Provider.of<PenjualanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: keranjangController.keranjangList.isEmpty
          ? Center(child: Text('Keranjang Anda Kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Keranjang',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: keranjangController.keranjangList.length,
              itemBuilder: (context, index) {
                final item = keranjangController.keranjangList[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(item.namaProduk, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text('Qty: ${item.jumlah} - Rp${item.totalHarga.toStringAsFixed(0)}', style: TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        keranjangController.hapusDariKeranjang(item.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Bagian total belanja dan informasi tambahan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50, // Background warna yang berbeda
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Total Belanja: Rp${keranjangController.totalHarga.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: bayarController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Dibayar',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        double dibayar = double.tryParse(value) ?? 0.0;
                        kembalian = dibayar - keranjangController.totalHarga;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Kembalian: Rp${kembalian < 0 ? 0.0 : kembalian.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kembalian < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (kembalian >= 0) {
                  // Simpan penjualan dan data keranjang ke file JSON
                  penjualanController.simpanPenjualan(
                    keranjangController.keranjangList,
                    keranjangController.totalHarga,
                    double.parse(bayarController.text),
                    kembalian,
                  );
                  keranjangController.keranjangList.clear(); // Bersihkan keranjang
                  keranjangController.notifyListeners(); // Memberitahu bahwa keranjang telah diperbarui
                  penjualanController.simpanPenjualanKeFile(); // Pastikan penjualan disimpan
                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout Berhasil!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah dibayar kurang!')));
                }
              },
              child: Text('Selesaikan Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.amber,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),// Membuat tombol lebih lebar
              ),
            ),
          ),
        ],
      ),
    );
  }
}
