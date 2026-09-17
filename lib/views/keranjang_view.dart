import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/produk_controller.dart';
import '../controllers/keranjang_controller.dart';
import '../controllers/kategori_controller.dart';
import '../helpers/format_helper.dart';
import '../models/produk.dart';
import '../models/keranjang.dart';
import '../models/kategori.dart';
import '../widgets/foto_thumbnail.dart';
import '../widgets/tap_scale.dart';
import 'barcode_scanner_view.dart';

class KeranjangView extends StatefulWidget {
  // true hanya saat tab Keranjang ini yang sedang tampil di bottom navigation - dipakai supaya
  // field pemindai barcode fisik (tersembunyi) hanya menahan fokus ketika layar ini aktif,
  // dan tidak "membajak" input di tab/dialog lain.
  final bool active;

  const KeranjangView({super.key, required this.active});

  @override
  State<KeranjangView> createState() => _KeranjangViewState();
}

class _KeranjangViewState extends State<KeranjangView> {
  List<int> selectedKeranjangIds = [];
  bool selectAll = false;

  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.active) _scanFocusNode.requestFocus();
  }

  @override
  void didUpdateWidget(covariant KeranjangView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _scanFocusNode.requestFocus();
    } else if (!widget.active && oldWidget.active) {
      _scanFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _scanFocusNode.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // Dipakai bersama oleh jalur scan kamera dan jalur alat scanner fisik, supaya perilaku
  // (cek stok, gabung ke keranjang, pesan hasil) selalu sama persis dengan tombol "+" biasa.
  ({bool sukses, String pesan}) _prosesScanBarcode(String kodeMentah) {
    final kode = kodeMentah.trim();
    if (kode.isEmpty) return (sukses: false, pesan: '');

    final produkController = context.read<ProdukController>();
    final keranjangController = context.read<KeranjangController>();

    Produk? produk;
    for (final p in produkController.produkList) {
      if (p.barcode == kode) {
        produk = p;
        break;
      }
    }

    if (produk == null) {
      return (sukses: false, pesan: 'Barcode "$kode" tidak ditemukan');
    }

    final sisaStok =
        produk.stok - keranjangController.jumlahDiKeranjang(produk.id!);
    if (sisaStok <= 0) {
      return (sukses: false, pesan: 'Stok "${produk.namaProduk}" habis');
    }

    final produkId = produk.id!;
    final namaProduk = produk.namaProduk;
    keranjangController.tambahKeKeranjang(
      Keranjang(
          id: produkId, namaProduk: namaProduk, harga: produk.harga, jumlah: 1),
    );
    // Produk yang berhasil di-scan langsung dicentang di keranjang, supaya setelah selesai
    // scan (mungkin beberapa barang berturut-turut) tinggal tap Checkout sekali tanpa perlu
    // mencentang manual satu-satu.
    setState(() {
      if (!selectedKeranjangIds.contains(produkId)) {
        selectedKeranjangIds.add(produkId);
      }
      selectAll = selectedKeranjangIds.length ==
          keranjangController.keranjangList.length;
    });
    return (sukses: true, pesan: '$namaProduk ditambahkan');
  }

  // Kamera dibuka sekali-pindai: begitu satu barcode terbaca (sudah berbunyi "klik" di
  // BarcodeScannerView), kamera langsung tertutup sendiri lalu di sini kita proses hasilnya
  // dan langsung lanjut ke Checkout - kasir tidak perlu berdiam di layar kamera.
  Future<void> _bukaScannerKamera() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerView(title: 'Pindai Barcode')),
    );
    if (!mounted) return;
    if (widget.active) _scanFocusNode.requestFocus();
    if (kode == null) return;

    final hasil = _prosesScanBarcode(kode);
    if (!hasil.sukses) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(hasil.pesan)));
      return;
    }

    final keranjangController = context.read<KeranjangController>();
    final selectedItems = keranjangController.keranjangList
        .where((item) => selectedKeranjangIds.contains(item.id))
        .toList();
    await Navigator.pushNamed(context, '/checkout', arguments: selectedItems);
    if (!mounted) return;
    // Transaksi yang selesai di Checkout sudah memotong stok di database; muat ulang supaya
    // daftar produk (termasuk label sisa stok) ikut terbarui. Lihat juga jalur tombol Checkout.
    await context.read<ProdukController>().loadProduk();
  }

  @override
  Widget build(BuildContext context) {
    final produkController = context.watch<ProdukController>();
    final keranjangController = context.watch<KeranjangController>();
    final kategoriList = context.watch<KategoriController>().kategoriList;

    // DefaultTabController membuat & membuang TabController secara aman lewat siklus hidup
    // widget-nya sendiri. Key berbasis jumlah kategori memaksa remount bersih (bukan tukar
    // controller di tengah build) saat kategori bertambah/berkurang - mencegah crash TabController.
    return DefaultTabController(
      key: ValueKey(kategoriList.length),
      length: kategoriList.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produk & Keranjang'),
          actions: [
            IconButton(
              tooltip: 'Pindai Barcode',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _bukaScannerKamera,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.amber.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.amber.shade700,
            tabs: [
              const Tab(text: 'Semua'),
              ...kategoriList
                  .map((kategori) => Tab(text: kategori.namaKategori)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Field tak terlihat untuk alat scanner fisik (USB/Bluetooth mode keyboard):
            // alat semacam ini hanya mengetik angka barcode + Enter ke field yang sedang
            // fokus, jadi cukup field kosong berukuran 0 yang selalu fokus saat tab ini aktif.
            SizedBox(
              width: 0,
              height: 0,
              child: TextField(
                controller: _scanController,
                focusNode: _scanFocusNode,
                showCursor: false,
                keyboardType: TextInputType.none,
                decoration: const InputDecoration.collapsed(hintText: ''),
                onSubmitted: (kode) {
                  final hasil = _prosesScanBarcode(kode);
                  _scanController.clear();
                  if (widget.active) _scanFocusNode.requestFocus();
                  if (hasil.pesan.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(hasil.pesan),
                          duration: const Duration(milliseconds: 1200)),
                    );
                  }
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: TabBarView(
                children: [
                  _buildProdukList(produkController.produkList, kategoriList,
                      keranjangController),
                  ...kategoriList.map((kategori) {
                    final produkByKategori = produkController.produkList
                        .where((p) => p.kategoriId == kategori.id)
                        .toList();
                    return _buildProdukList(
                        produkByKategori, kategoriList, keranjangController);
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 2,
              child: _buildKeranjangPanel(
                  context, keranjangController, produkController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdukList(List<Produk> produkList, List<Kategori> kategoriList,
      KeranjangController keranjangController) {
    if (produkList.isEmpty) {
      return Center(
          child: Text('Tidak ada produk.',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = produkList[index];
        final diKeranjang = keranjangController.jumlahDiKeranjang(produk.id!);
        final sisaStok = produk.stok - diKeranjang;
        final habis = sisaStok <= 0;
        void tambah() {
          keranjangController.tambahKeKeranjang(
            Keranjang(
                id: produk.id!,
                namaProduk: produk.namaProduk,
                harga: produk.harga,
                jumlah: 1),
          );
        }

        // Seluruh kartu bisa diketuk untuk menambah ke keranjang - kasir sering menambah
        // barang yang sama berulang kali, jadi target tapnya dibuat sebesar mungkin.
        // Isi kartu (nama 2 baris, kategori, badge stok, harga) mengikuti pola grid
        // yang sama seperti ProdukView biar kedua layar tampak konsisten.
        final kategori = kategoriList.firstWhere(
          (k) => k.id == produk.kategoriId,
          orElse: () => Kategori(namaKategori: 'Tanpa kategori'),
        );
        return Stack(
          children: [
            TapScale(
              onTap: habis ? null : tambah,
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
                              Text(
                                kategori.namaKategori,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: habis
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habis ? 'Stok habis' : 'Stok $sisaStok',
                                  style: TextStyle(
                                    color: habis
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
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
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800),
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
                  icon: Icon(
                    Icons.add,
                    size: 22,
                    color: habis ? Colors.grey.shade400 : Colors.amber.shade800,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.85),
                  ),
                  tooltip: 'Tambah ke keranjang',
                  onPressed: habis ? null : tambah,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKeranjangPanel(
      BuildContext context,
      KeranjangController keranjangController,
      ProdukController produkController) {
    final items = keranjangController.keranjangList;
    final total = items
        .where((item) => selectedKeranjangIds.contains(item.id))
        .fold<double>(0.0, (t, item) => t + item.totalHarga);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Keranjang',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (keranjangController.totalItem > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${keranjangController.totalItem} item',
                        style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                const Spacer(),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectAll = !selectAll;
                        selectedKeranjangIds =
                            selectAll ? items.map((e) => e.id).toList() : [];
                      });
                    },
                    child:
                        Text(selectAll ? 'Batal pilih semua' : 'Pilih semua'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Keranjang kosong.',
                        style: TextStyle(color: Colors.grey.shade600)))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final checked = selectedKeranjangIds.contains(item.id);
                      final produk = produkController.produkList.firstWhere(
                        (p) => p.id == item.id,
                        orElse: () => Produk(
                            id: item.id,
                            namaProduk: item.namaProduk,
                            harga: item.harga,
                            kategoriId: 0),
                      );
                      final habis = produk.stok <= 0;
                      final sisaStok = produk.stok - item.jumlah;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: checked
                            ? Colors.amber.shade50.withOpacity(0.25)
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                          leading: SizedBox(
                            width: 64,
                            height: 64,
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: FotoThumbnail(
                                path: produk.fotoProduk,
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 6,
                              ),
                            ),
                          ),
                          title: Text(
                            item.namaProduk,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: habis
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habis ? 'Stok habis' : 'Stok $sisaStok',
                                  style: TextStyle(
                                    color: habis
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.jumlah} x Rp${FormatHelper.rupiah(item.harga)} = Rp${FormatHelper.rupiah(item.totalHarga)}',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 32,
                                child: Checkbox(
                                  value: checked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedKeranjangIds.add(item.id);
                                      } else {
                                        selectedKeranjangIds.remove(item.id);
                                      }
                                      selectAll = selectedKeranjangIds.length ==
                                          items.length;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  tooltip: 'Hapus item',
                                  onPressed: () {
                                    keranjangController
                                        .hapusDariKeranjang(item.id);
                                    setState(() {
                                      selectedKeranjangIds.remove(item.id);
                                      selectAll = selectedKeranjangIds.length ==
                                          keranjangController
                                              .keranjangList.length;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total dipilih',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Rp${FormatHelper.rupiah(total)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.amber.shade800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: selectedKeranjangIds.isEmpty
                        ? null
                        : () async {
                            final selectedItems = items
                                .where((item) =>
                                    selectedKeranjangIds.contains(item.id))
                                .toList();
                            await Navigator.pushNamed(context, '/checkout',
                                arguments: selectedItems);
                            if (!mounted) return;
                            // Stok di database sudah dipotong oleh transaksi tadi, tapi daftar
                            // produk di memori masih memegang nilai lama - tanpa dimuat ulang,
                            // kartu produk tetap menampilkan sisa stok sebelum transaksi.
                            await this
                                .context
                                .read<ProdukController>()
                                .loadProduk();
                            if (!mounted) return;
                            setState(() => selectedKeranjangIds.removeWhere(
                                (id) => !keranjangController.keranjangList
                                    .any((item) => item.id == id)));
                          },
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
