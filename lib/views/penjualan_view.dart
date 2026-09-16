import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/penjualan_controller.dart';
import '../helpers/format_helper.dart';
import '../helpers/struk_helper.dart';
import '../models/penjualan.dart';

class PenjualanView extends StatefulWidget {
  const PenjualanView({super.key});

  @override
  State<PenjualanView> createState() => _PenjualanViewState();
}

class _PenjualanViewState extends State<PenjualanView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _rentangTanggal;

  @override
  void initState() {
    super.initState();
    Provider.of<PenjualanController>(context, listen: false).muatPenjualan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cocok kalau tanggal transaksi ada di antara awal-akhir rentang (inklusif), termasuk
  // seluruh hari terakhir (bukan cuma sampai jam 00:00) supaya transaksi di hari itu tidak
  // ketinggalan. Rentang dengan tanggal awal = akhir otomatis berfungsi sebagai filter 1 hari.
  bool _dalamRentang(DateTime tanggal) {
    final rentang = _rentangTanggal;
    if (rentang == null) return true;
    final mulai = DateTime(rentang.start.year, rentang.start.month, rentang.start.day);
    final akhir = DateTime(rentang.end.year, rentang.end.month, rentang.end.day, 23, 59, 59, 999);
    return !tanggal.isBefore(mulai) && !tanggal.isAfter(akhir);
  }

  Future<void> _pilihRentangTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: sekarang,
      initialDateRange: _rentangTanggal ?? DateTimeRange(start: sekarang, end: sekarang),
      helpText: 'Pilih rentang tanggal (pilih tanggal yang sama untuk 1 hari)',
      saveText: 'Simpan',
    );
    if (hasil != null) {
      setState(() => _rentangTanggal = hasil);
    }
  }

  String _labelRentang(DateTimeRange rentang) {
    final format = DateFormat('dd/MM/yyyy');
    final sama = rentang.start.year == rentang.end.year && rentang.start.month == rentang.end.month && rentang.start.day == rentang.end.day;
    return sama ? format.format(rentang.start) : '${format.format(rentang.start)} - ${format.format(rentang.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final penjualanController = context.watch<PenjualanController>();

    var filtered = penjualanController.daftarPenjualan.where((p) => _dalamRentang(p.tanggal)).toList();
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.formattedTanggal.toLowerCase().contains(query) ||
            p.daftarProduk.any((item) => item.namaProduk.toLowerCase().contains(query));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari tanggal atau nama produk...',
              ),
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pilihRentangTanggal,
                  icon: Icon(Icons.date_range, size: 18, color: Colors.amber.shade800),
                  label: const Text('Filter Rentang Tanggal', style: TextStyle(color: Colors.black87)),
                ),
                if (_rentangTanggal != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Chip(
                      label: Text(_labelRentang(_rentangTanggal!), overflow: TextOverflow.ellipsis),
                      onDeleted: () => setState(() => _rentangTanggal = null),
                      backgroundColor: Colors.amber.shade50,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: penjualanController.isLoading && penjualanController.daftarPenjualan.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          penjualanController.daftarPenjualan.isEmpty ? 'Belum ada transaksi.' : 'Tidak ada transaksi yang cocok.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final penjualan = filtered[index];
                          return Card(
                            child: ListTile(
                              title: Text(penjualan.formattedTanggal, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${penjualan.daftarProduk.length} produk'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Rp${FormatHelper.rupiah(penjualan.totalHarga)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    onPressed: () => _printPenjualan(penjualan),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _hapusPenjualan(context, penjualanController, penjualan),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusPenjualan(BuildContext context, PenjualanController controller, Penjualan penjualan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus transaksi tanggal ${penjualan.formattedTanggal}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await controller.hapusPenjualan(penjualan);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _printPenjualan(Penjualan penjualan) async {
    try {
      await StrukHelper.cetakStruk(penjualan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak: $e')));
    }
  }
}
