import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FotoHelper {
  static Future<Directory> _folderFoto() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'product_photos'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  // Menyalin foto yang dipilih ke folder aplikasi supaya tidak hilang kalau file asal
  // (di galeri/cache kamera) dihapus. Mengembalikan path baru untuk disimpan di database.
  static Future<String> simpanFotoProduk(File sourceFile) async {
    final folder = await _folderFoto();
    final ekstensi = p.extension(sourceFile.path);
    final namaFile = 'produk_${DateTime.now().millisecondsSinceEpoch}$ekstensi';
    final tujuan = File(p.join(folder.path, namaFile));
    await sourceFile.copy(tujuan.path);
    return tujuan.path;
  }

  static Future<Directory> _folderLogo() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'logo'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  // Sama dengan simpanFotoProduk, khusus logo toko: file hasil pilih (di galeri/cache)
  // disalin ke folder aplikasi supaya path-nya stabil dan aman disimpan di pengaturan.
  static Future<String> simpanLogo(File sourceFile) async {
    final folder = await _folderLogo();
    final ekstensi = p.extension(sourceFile.path);
    final namaFile = 'logo_${DateTime.now().millisecondsSinceEpoch}$ekstensi';
    final tujuan = File(p.join(folder.path, namaFile));
    await sourceFile.copy(tujuan.path);
    return tujuan.path;
  }

  // Hapus foto lama secara best-effort (tidak melempar error kalau path null atau file sudah tidak ada).
  static Future<void> hapusFotoJikaAda(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Bukan operasi kritis: kegagalan hapus file tidak boleh menghentikan alur utama.
    }
  }
}
