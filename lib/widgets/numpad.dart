import 'package:flutter/material.dart';

// Numpad kustom untuk input nominal Rupiah (bilangan bulat, tanpa titik desimal - sama
// seperti input harga produk yang sudah ada) - menggantikan keyboard OS yang lambat
// muncul dan menutupi layar checkout.
class Numpad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const Numpad({super.key, required this.value, required this.onChanged});

  static const _tombol = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', '⌫'],
  ];

  void _tekan(String label) {
    switch (label) {
      case 'C':
        onChanged('');
        return;
      case '⌫':
        if (value.isEmpty) return;
        onChanged(value.substring(0, value.length - 1));
        return;
      default:
        // Hindari nol berulang di depan (mis. "0" + "5" jadi "5", bukan "05").
        const maxDigit = 10;
        if (value.length >= maxDigit) return;
        final baru = value == '0' || value.isEmpty ? label : '$value$label';
        onChanged(baru);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _tombol
          .map(
            (baris) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: baris
                    .map(
                      (label) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TombolNumpad(label: label, onTap: () => _tekan(label)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TombolNumpad extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TombolNumpad({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final destruktif = label == 'C';
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: Colors.white,
          foregroundColor: destruktif ? Colors.redAccent : Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
