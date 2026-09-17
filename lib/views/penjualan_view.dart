import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/penjualan_controller.dart';
import '../helpers/format_helper.dart';
import '../helpers/struk_helper.dart';
import '../models/penjualan.dart';

// Riwayat penjualan dikelompokkan per hari (bukan daftar datar) supaya kasir bisa langsung
// menutup buku harian: tiap kelompok dibuka dengan satu baris rekapitulasi (jumlah transaksi,
// rupiah yang masuk, jumlah produk terjual), lalu transaksi-transaksinya di bawahnya.
class PenjualanView extends StatefulWidget {
  const PenjualanView({super.key});

  @override
  State<PenjualanView> createState() => _PenjualanViewState();
}

// Satu hari dalam riwayat: tanggalnya plus transaksi-transaksi yang terjadi di hari itu.
// Dipakai untuk memasangkan rekapitulasi dengan daftar transaksinya.
class _KelompokHarian {
  final DateTime tanggal;
  final List<Penjualan> transaksi;

  _KelompokHarian(this.tanggal, this.transaksi);

  double get totalPenjualan => transaksi.fold<double>(0.0, (t, p) => t + p.totalHarga);
  int get jumlahTransaksi => transaksi.length;
  int get jumlahProdukTerjual => transaksi.fold<int>(0, (t, p) => t + p.daftarProduk.fold<int>(0, (s, item) => s + item.jumlah));
}

class _PenjualanViewState extends State<PenjualanView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _rentangTanggal;

  static const List<String> _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const List<String> _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

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

  // Ambil bagian tanggalnya saja sebagai kunci kelompok. Transaksi yang terjadi di hari yang
  // sama selalu jatuh ke kunci yang identik, sedangkan urutan menurun dari database membuat
  // hari terbaru muncul lebih dulu.
  DateTime _hariDari(DateTime tanggal) => DateTime(tanggal.year, tanggal.month, tanggal.day);

  // Label hari dibuat relatif dulu ("Hari ini", "Kemarin") karena itu yang paling cepat
  // dikenali kasir; hari yang lebih lama baru ditulis lengkap dengan nama hari.
  String _labelHari(DateTime hari) {
    final sekarang = DateTime.now();
    final selisih = _hariDari(sekarang).difference(hari).inDays;
    // Dibuat manual (bukan DateFormat ber-locale) supaya tidak perlu inisialisasi data simbol
    // tanggal per locale, dan nama hari/bulan selalu konsisten Bahasa Indonesia.
    final tanggalLengkap = '${_namaHari[hari.weekday - 1]}, ${hari.day} ${_namaBulan[hari.month - 1]} ${hari.year}';
    if (selisih == 0) return 'Hari ini · $tanggalLengkap';
    if (selisih == 1) return 'Kemarin · $tanggalLengkap';
    return tanggalLengkap;
  }

  // Transaksi dipecah per hari tanpa mengubah urutannya, lalu tiap kelompok dihitung totalnya.
  List<_KelompokHarian> _kelompokkanPerHari(List<Penjualan> transaksi) {
    final urutanHari = <DateTime>[];
    final peta = <DateTime, List<Penjualan>>{};

    for (final p in transaksi) {
      final hari = _hariDari(p.tanggal);
      final daftar = peta.putIfAbsent(hari, () {
        urutanHari.add(hari);
        return <Penjualan>[];
      });
      daftar.add(p);
    }

    return urutanHari.map((hari) => _KelompokHarian(hari, peta[hari]!)).toList();
  }

  // Ringkasan produk dalam satu transaksi. Nama produk ditulis apa adanya supaya kasir bisa
  // memastikan barang apa yang terjual tanpa harus membuka struk; jumlah lebih dari satu
  // dibuat eksplisit ("Beras 5kg x2") agar tidak terbaca sebagai dua barang berbeda.
  String _ringkasanProduk(Penjualan penjualan) {
    return penjualan.daftarProduk
        .map((item) => item.jumlah > 1 ? '${item.namaProduk} x${item.jumlah}' : item.namaProduk)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final penjualanController = context.watch<PenjualanController>();

    // Pencarian mencocokkan teks yang benar-benar terlihat di daftar (tanggal dan tulisan
    // "Hari ini"/"Kemarin" ikut dicari) plus nama produk, supaya query seperti "produk a"
    // atau "kemarin" sama-sama masuk akal bagi kasir.
    var filtered = penjualanController.daftarPenjualan.where((p) => _dalamRentang(p.tanggal)).toList();
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return _labelHari(_hariDari(p.tanggal)).toLowerCase().contains(query) ||
            p.formattedTanggal.toLowerCase().contains(query) ||
            p.daftarProduk.any((item) => item.namaProduk.toLowerCase().contains(query));
      }).toList();
    }

    final kelompok = _kelompokkanPerHari(filtered);

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
                : kelompok.isEmpty
                    ? Center(
                        child: Text(
                          penjualanController.daftarPenjualan.isEmpty ? 'Belum ada transaksi.' : 'Tidak ada transaksi yang cocok.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: kelompok.length,
                        itemBuilder: (context, index) {
                          final grup = kelompok[index];
                          return _HariSection(
                            grup: grup,
                            labelHari: _labelHari(grup.tanggal),
                            ringkasanProduk: _ringkasanProduk,
                            onPrint: _printPenjualan,
                            onDelete: (penjualan) => _hapusPenjualan(context, penjualanController, penjualan),
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

// Satu blok hari: header rekapitulasi + transaksi-transaksinya. Pemisah antar hari adalah
// header ini sendiri - warnanya dibuat berbeda dari kartu transaksi supaya batas pergantian
// hari langsung terlihat saat menggulir, tanpa perlu garis dekoratif tambahan.
class _HariSection extends StatelessWidget {
  final _KelompokHarian grup;
  final String labelHari;
  final String Function(Penjualan) ringkasanProduk;
  final void Function(Penjualan) onPrint;
  final void Function(Penjualan) onDelete;

  const _HariSection({
    required this.grup,
    required this.labelHari,
    required this.ringkasanProduk,
    required this.onPrint,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RekapHarian(grup: grup, labelHari: labelHari),
          const SizedBox(height: 8),
          for (final penjualan in grup.transaksi)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _KartuTransaksi(
                penjualan: penjualan,
                ringkasanProduk: ringkasanProduk(penjualan),
                onPrint: () => onPrint(penjualan),
                onDelete: () => onDelete(penjualan),
              ),
            ),
        ],
      ),
    );
  }
}

class _RekapHarian extends StatelessWidget {
  final _KelompokHarian grup;
  final String labelHari;

  const _RekapHarian({required this.grup, required this.labelHari});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labelHari, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${grup.jumlahTransaksi} transaksi · ${grup.jumlahProdukTerjual} produk terjual',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp${FormatHelper.rupiah(grup.totalPenjualan)}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }
}

class _KartuTransaksi extends StatelessWidget {
  final Penjualan penjualan;
  final String ringkasanProduk;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  const _KartuTransaksi({
    required this.penjualan,
    required this.ringkasanProduk,
    required this.onPrint,
    required this.onDelete,
  });

  String get _jam => DateFormat('HH:mm').format(penjualan.tanggal);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi $_jam',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ringkasanProduk,
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${penjualan.daftarProduk.length} jenis produk',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp${FormatHelper.rupiah(penjualan.totalHarga)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Cetak struk',
                      icon: const Icon(Icons.print_outlined),
                      onPressed: onPrint,
                    ),
                    IconButton(
                      tooltip: 'Hapus transaksi',
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}