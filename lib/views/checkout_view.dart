import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/keranjang_controller.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.teal,
      ),
      body: keranjangController.keranjangList.isEmpty
          ? Center(child: Text('Keranjang Anda Kosong'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: keranjangController.keranjangList.length,
              itemBuilder: (context, index) {
                final item = keranjangController.keranjangList[index];
                return ListTile(
                  title: Text(item.namaProduk),
                  subtitle: Text('Qty: ${item.jumlah} - Rp${item.totalHarga.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      keranjangController.hapusDariKeranjang(item.id);
                    },
                  ),
                );
              },
            ),
          ),
          // Bagian total belanja dan informasi tambahan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Total Belanja: Rp${keranjangController.totalHarga.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: bayarController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Batasi input hanya angka
                  ],
                  decoration: InputDecoration(
                    labelText: 'Jumlah Dibayar',
                    border: OutlineInputBorder(),
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
                  'Kembalian: Rp${kembalian < 0 ? 0.0 : kembalian.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kembalian < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (kembalian >= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Checkout Berhasil!')),
                  );
                  keranjangController.keranjangList.clear();
                  keranjangController.notifyListeners();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jumlah dibayar kurang!')),
                  );
                }
              },
              child: Text('Selesaikan Checkout'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
