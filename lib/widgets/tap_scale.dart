import 'package:flutter/material.dart';

// Feedback sentuh halus untuk kartu grid: mengecil sedikit saat ditekan, kembali normal
// saat dilepas. Dibangun dari GestureDetector + AnimatedScale bawaan Flutter (tanpa
// dependency animasi tambahan), sesuai dial MOTION 1 (tap feedback saja, bukan hiasan).
// Kalau [onTap] null, animasi tidak pernah jalan - jadi kartu nonaktif juga terasa nonaktif.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
