import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/keranjang_controller.dart';

class CheckoutView extends StatelessWidget {
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
                  subtitle: Text('Qty: ${item.jumlah} - \$${item.totalHarga.toStringAsFixed(2)}')
                );
              },
            ),
          ),
          // Bagian total harga dan tombol checkout
          Padding(
            padding: const EdgeInsets.all(16.0),
              child: Text(
                'Total: \$${keranjangController.totalHarga.toStringAsFixed(2)} - Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
