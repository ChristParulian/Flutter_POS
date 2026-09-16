import 'dart:io';

import 'package:flutter/material.dart';

// Thumbnail foto produk yang dipakai bersama di daftar produk, kartu grid, dan preview
// dialog tambah/edit - supaya logikanya (file ada/tidak, placeholder) tidak diduplikasi.
class FotoThumbnail extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final double borderRadius;

  const FotoThumbnail({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  const FotoThumbnail.square({
    super.key,
    required this.path,
    required double ukuran,
    this.borderRadius = 8,
  })  : width = ukuran,
        height = ukuran;

  @override
  Widget build(BuildContext context) {
    if (path != null && File(path!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(File(path!), width: width, height: height, fit: BoxFit.cover),
      );
    }
    // width/height bisa double.infinity (dipakai bersama AspectRatio untuk foto full-bleed
    // di kartu grid) - ukuran ikon placeholder harus tetap angka wajar/berhingga, tidak boleh
    // ikut infinity, atau layout ikon (dirender lewat font) akan gagal total.
    final acuan = [width, height].firstWhere((v) => v != null && v.isFinite, orElse: () => 48.0)!;
    final ukuranIkon = acuan * 0.5;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(borderRadius)),
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: ukuranIkon),
    );
  }
}
