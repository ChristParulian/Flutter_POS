import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/kategori_controller.dart';
import '../models/kategori.dart';

class KategoriView extends StatefulWidget {
  const KategoriView({super.key});

  @override
  State<KategoriView> createState() => _KategoriViewState();
}

class _KategoriViewState extends State<KategoriView> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari kategori...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<KategoriController>(
              builder: (context, kategoriController, child) {
                if (kategoriController.isLoading && kategoriController.kategoriList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final searchQuery = _searchController.text.toLowerCase();
                final filteredList = kategoriController.kategoriList
                    .where((kategori) => kategori.namaKategori.toLowerCase().contains(searchQuery))
                    .toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      kategoriController.kategoriList.isEmpty
                          ? 'Belum ada kategori. Tambahkan kategori pertama Anda.'
                          : 'Tidak ada kategori yang cocok dengan pencarian.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final kategori = filteredList[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade50,
                          child: Icon(Icons.category, color: Colors.amber.shade700),
                        ),
                        title: Text(kategori.namaKategori, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                _controller.text = kategori.namaKategori;
                                _showUpdateDialog(context, kategori);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(context, kategori),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    _controller.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Kategori'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = _controller.text.trim();
                if (nama.isEmpty) return;
                final kategoriController = Provider.of<KategoriController>(context, listen: false);
                Navigator.pop(dialogContext);
                await kategoriController.addKategori(Kategori(namaKategori: nama));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil ditambahkan')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, Kategori kategori) {
    _controller.text = kategori.namaKategori;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Kategori'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = _controller.text.trim();
                if (nama.isEmpty) return;
                final kategoriController = Provider.of<KategoriController>(context, listen: false);
                Navigator.pop(dialogContext);
                await kategoriController.updateKategori(Kategori(id: kategori.id, namaKategori: nama));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil diperbarui')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Kategori kategori) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Kategori'),
          content: Text('Yakin ingin menghapus kategori "${kategori.namaKategori}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final kategoriController = Provider.of<KategoriController>(context, listen: false);
                Navigator.pop(dialogContext);
                try {
                  await kategoriController.deleteKategori(kategori.id!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil dihapus')),
                  );
                } on KategoriMasihDipakaiException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tidak bisa dihapus: masih dipakai ${e.jumlahProduk} produk. Pindahkan atau hapus produk itu dulu.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
