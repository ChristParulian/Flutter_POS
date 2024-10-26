import 'package:flutter/material.dart';
import 'database_helper.dart'; // Pastikan ini ada dan benar
import 'models/product.dart'; // Sesuaikan dengan path jika menggunakan folder models

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _databaseHelper = DatabaseHelper();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    List<Product> products = await _databaseHelper.getProducts();
    setState(() {
      _products = products;
    });
  }

  void _addProduct(String name, String description, int categoryId) async {
    if (name.isNotEmpty && description.isNotEmpty) {
      await _databaseHelper.insertProduct(
        Product(
          name: name,
          description: description,
          categoryId: categoryId,
        ),
      );
      _loadProducts();
    }
  }

  void _showAddProductDialog() {
    final TextEditingController _productNameController = TextEditingController();
    final TextEditingController _productDescriptionController = TextEditingController();
    final TextEditingController _categoryIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'Product Description'),
              ),
              TextField(
                controller: _categoryIdController,
                decoration: InputDecoration(labelText: 'Category ID'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                _addProduct(
                  _productNameController.text,
                  _productDescriptionController.text,
                  int.parse(_categoryIdController.text),
                );
                Navigator.of(context).pop(); // Menutup dialog setelah menambah produk
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int? id) async {
    if (id != null) {
      await _databaseHelper.deleteProduct(id);
      _loadProducts(); // Memuat ulang produk setelah penghapusan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog, // Menampilkan dialog untuk menambahkan produk
        child: Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text(product.description),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteProduct(product.id), // Delete action
          ),
        );
      },
    );
  }
}
