import 'package:flutter/material.dart';
import 'models/category.dart';
import 'database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _databaseHelper = DatabaseHelper();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    List<Category> categories = await _databaseHelper.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _addCategory(String name) async {
    if (name.isNotEmpty) {
      await _databaseHelper.insertCategory(Category(name: name));
      _loadCategories();
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController _categoryNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
          content: TextField(
            controller: _categoryNameController,
            decoration: InputDecoration(labelText: 'Category Name'),
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
                _addCategory(_categoryNameController.text);
                Navigator.of(context).pop(); // Menutup dialog setelah menambah kategori
              },
            ),
          ],
        );
      },
    );
  }

  void _updateCategory(Category category) async {
    String name = category.name; // Ambil nama kategori untuk diedit
    // Menampilkan dialog untuk memperbarui kategori
    final TextEditingController _categoryNameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Category'),
          content: TextField(
            controller: _categoryNameController,
            decoration: InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                _updateCategoryName(category, _categoryNameController.text);
                Navigator.of(context).pop(); // Menutup dialog setelah memperbarui kategori
              },
            ),
          ],
        );
      },
    );
  }

  void _updateCategoryName(Category category, String newName) async {
    if (newName.isNotEmpty) {
      await _databaseHelper.updateCategory(Category(id: category.id, name: newName));
      _loadCategories();
    }
  }

  void _deleteCategory(int? id) async {
    if (id != null) { // Pastikan id tidak null
      await _databaseHelper.deleteCategory(id);
      _loadCategories(); // Memuat ulang kategori setelah penghapusan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildCategoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog, // Menampilkan dialog untuk menambahkan kategori
        child: Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return ListTile(
          title: Text(category.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _updateCategory(category); // Memperbarui kategori
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteCategory(category.id), // Delete action
              ),
            ],
          ),
        );
      },
    );
  }
}
