import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/produk_controller.dart';
import '../controllers/kategori_controller.dart';
import '../helpers/foto_helper.dart';
import '../helpers/format_helper.dart';
import '../models/produk.dart';
import '../models/kategori.dart';
import '../widgets/foto_thumbnail.dart';
import '../widgets/tap_scale.dart';
import 'barcode_scanner_view.dart';

class ProdukView extends StatefulWidget {
  const ProdukView({super.key});

  @override
  State<ProdukView> createState() => _ProdukViewState();
}

class _ProdukViewState extends State<ProdukView> {
  int? _selectedKategoriId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProdukDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari produk...',
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Consumer<KategoriController>(
            builder: (context, kategoriController, child) {
              if (kategoriController.kategoriList.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _kategoriChip(null, 'Semua'),
                    ...kategoriController.kategoriList.map((k) => _kategoriChip(k.id, k.namaKategori)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer2<ProdukController, KategoriController>(
              builder: (context, produkController, kategoriController, child) {
                if (produkController.isLoading && produkController.produkList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Produk> produkList = produkController.produkList;
                if (_selectedKategoriId != null) {
                  produkList = produkList.where((p) => p.kategoriId == _selectedKategoriId).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  produkList = produkList.where((p) => p.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (produkList.isEmpty) {
                  return Center(
                    child: Text(
                      produkController.produkList.isEmpty ? 'Belum ada produk. Tambahkan produk pertama Anda.' : 'Tidak ada produk yang cocok.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: produkList.length,
                  itemBuilder: (context, index) {
                    final produk = produkList[index];
                    final kategori = kategoriController.kategoriList.firstWhere(
                      (k) => k.id == produk.kategoriId,
                      orElse: () => Kategori(namaKategori: 'Tanpa kategori'),
                    );
                    final habis = produk.stok <= 0;
                    // Ketuk kartu untuk edit (target tap besar & alami); hapus tetap tombol
                    // kecil terpisah di pojok foto supaya aksi destruktif butuh ketukan yang
                    // sengaja, bukan tercampur dengan zona "buka edit".
                    //
                    // Tombol hapus SENGAJA jadi sibling TapScale di Stack luar (bukan anak di
                    // dalam subtree TapScale) - kalau dua GestureDetector bertumpuk (ancestor &
                    // descendant) keduanya bisa sama-sama terpicu dalam satu ketukan. Sebagai
                    // sibling di Stack yang sama, hit-test berhenti begitu tombol hapus (dites
                    // lebih dulu karena di atas) mengenai titik ketukan, sehingga TapScale di
                    // bawahnya tidak ikut terpicu untuk ketukan yang sama.
                    return Stack(
                      children: [
                        TapScale(
                          onTap: () => _showProdukDialog(context, produk: produk),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: FotoThumbnail(
                                    path: produk.fotoProduk,
                                    width: double.infinity,
                                    height: double.infinity,
                                    borderRadius: 0,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produk.namaProduk,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(kategori.namaKategori, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: habis ? Colors.red.shade50 : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              habis ? 'Stok habis' : 'Stok ${produk.stok}',
                                              style: TextStyle(
                                                color: habis ? Colors.red.shade700 : Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp${FormatHelper.rupiah(produk.harga)}',
                                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.85),
                              ),
                              onPressed: () => _showDeleteProdukDialog(context, produk),
                            ),
                          ),
                        ),
                      ],
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

  Widget _kategoriChip(int? id, String label) {
    final selected = _selectedKategoriId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedKategoriId = id),
        selectedColor: Colors.amber.shade700,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Future<void> _pilihFoto(BuildContext dialogContext, StateSetter setDialogState, void Function(String path) onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: dialogContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1280);
    if (file == null) return;

    final path = await FotoHelper.simpanFotoProduk(File(file.path));
    onPicked(path);
    setDialogState(() {});
  }

  Future<void> _scanBarcodeUntukForm(BuildContext dialogContext, TextEditingController barcodeController, StateSetter setDialogState) async {
    final hasil = await Navigator.push<String>(
      dialogContext,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView(title: 'Pindai Barcode Produk')),
    );
    if (hasil != null && hasil.isNotEmpty) {
      setDialogState(() => barcodeController.text = hasil);
    }
  }

  // Dialog Tambah/Edit Produk. Jika [produk] null berarti mode tambah, selain itu mode edit.
  Future<void> _showProdukDialog(BuildContext context, {Produk? produk}) async {
    final isEdit = produk != null;
    final namaController = TextEditingController(text: produk?.namaProduk ?? '');
    final hargaController = TextEditingController(text: produk != null ? produk.harga.toStringAsFixed(0) : '');
    final stokController = TextEditingController(text: produk != null ? produk.stok.toString() : '0');
    final barcodeController = TextEditingController(text: produk?.barcode ?? '');
    final kategoriList = Provider.of<KategoriController>(context, listen: false).kategoriList;
    // Jika kategori produk sudah tidak ada lagi di daftar (data lama yatim), jangan pilihkan nilai yang tidak valid ke dropdown.
    int? selectedKategoriId = produk != null && kategoriList.any((k) => k.id == produk.kategoriId) ? produk.kategoriId : null;
    String? errorText;

    final fotoAsli = produk?.fotoProduk;
    String? fotoDipilih = fotoAsli;
    bool disimpan = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pilihFoto(dialogContext, setDialogState, (path) => fotoDipilih = path),
                            child: FotoThumbnail.square(path: fotoDipilih, ukuran: 88),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _pilihFoto(dialogContext, setDialogState, (path) => fotoDipilih = path),
                                child: Text(fotoDipilih == null ? 'Tambah Foto' : 'Ubah Foto'),
                              ),
                              if (fotoDipilih != null)
                                TextButton(
                                  onPressed: () => setDialogState(() => fotoDipilih = null),
                                  child: const Text('Hapus'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(labelText: 'Nama Produk'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hargaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stokController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode (opsional)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Pindai barcode',
                          onPressed: () => _scanBarcodeUntukForm(dialogContext, barcodeController, setDialogState),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (kategoriList.isEmpty)
                      Text('Belum ada kategori. Buat kategori dulu.', style: TextStyle(color: Colors.red.shade700))
                    else
                      DropdownButtonFormField<int>(
                        value: selectedKategoriId,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: kategoriList
                            .map((k) => DropdownMenuItem<int>(value: k.id, child: Text(k.namaKategori)))
                            .toList(),
                        onChanged: (value) => selectedKategoriId = value,
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    final harga = double.tryParse(hargaController.text.trim());
                    final stok = int.tryParse(stokController.text.trim());
                    if (harga == null || stok == null || selectedKategoriId == null) {
                      setDialogState(() => errorText = 'Lengkapi semua data dengan angka yang valid');
                      return;
                    }

                    final produkController = Provider.of<ProdukController>(context, listen: false);
                    final barcodeTrim = barcodeController.text.trim();
                    final data = Produk(
                      id: produk?.id,
                      namaProduk: namaController.text.trim(),
                      harga: harga,
                      kategoriId: selectedKategoriId!,
                      stok: stok,
                      barcode: barcodeTrim.isEmpty ? null : barcodeTrim,
                      fotoProduk: fotoDipilih,
                    );

                    try {
                      if (isEdit) {
                        await produkController.updateProduk(data);
                        if (fotoDipilih != fotoAsli) {
                          await FotoHelper.hapusFotoJikaAda(fotoAsli);
                        }
                      } else {
                        await produkController.addProduk(data);
                      }
                      disimpan = true;
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Produk berhasil diperbarui' : 'Produk berhasil ditambahkan')),
                      );
                    } on ProdukTidakValidException catch (e) {
                      setDialogState(() => errorText = e.pesan);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dialog ditutup tanpa disimpan (Batal/tap di luar) tapi sempat memilih foto baru:
    // hapus file yang sudah ter-copy supaya tidak jadi sampah tak terpakai.
    if (!disimpan && fotoDipilih != fotoAsli) {
      await FotoHelper.hapusFotoJikaAda(fotoDipilih);
    }
  }

  void _showDeleteProdukDialog(BuildContext context, Produk produk) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus produk "${produk.namaProduk}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final produkController = Provider.of<ProdukController>(context, listen: false);
              Navigator.pop(dialogContext);
              await produkController.deleteProduk(produk.id!);
              await FotoHelper.hapusFotoJikaAda(produk.fotoProduk);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
