import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Layar kamera sekali-pindai: begitu satu barcode terdeteksi, berbunyi klik lalu langsung
// kembali (Navigator.pop) membawa kode itu ke pemanggil - dipakai untuk mengisi field
// barcode di form produk, dan untuk scan-tambah-ke-keranjang (yang lalu lanjut ke Checkout).
class BarcodeScannerView extends StatefulWidget {
  final String title;

  const BarcodeScannerView({super.key, this.title = 'Pindai Barcode'});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _sudahTerbaca = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_sudahTerbaca || capture.barcodes.isEmpty) return;
    final kode = capture.barcodes.first.rawValue;
    if (kode == null || kode.isEmpty) return;

    _sudahTerbaca = true;
    // Bunyi beep dari file suara sendiri (bukan suara sistem): suara sistem seperti
    // SystemSoundType.click ternyata sering senyap karena mengikuti setting "suara sentuh"
    // di perangkat, jadi tidak bisa diandalkan sebagai penanda scan berhasil.
    AudioPlayer().play(AssetSource('sounds/beep.wav'));
    Navigator.pop(context, kode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final aktif = state.torchState == TorchState.on;
              return IconButton(
                tooltip: 'Lampu senter',
                icon: Icon(aktif ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Izin kamera diperlukan untuk memindai barcode',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.shade700, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text('Arahkan kamera ke barcode', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
