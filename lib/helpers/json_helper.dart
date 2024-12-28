import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pos_flutter/models/keranjang.dart';

class JsonHelper {
  // Mendapatkan direktori penyimpanan
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Mendapatkan file untuk menyimpan data JSON
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/keranjang.json');
  }

  // Menyimpan data keranjang ke dalam file JSON
  Future<void> saveKeranjang(List<Keranjang> keranjangList) async {
    final file = await _localFile;

    // Mengonversi list keranjang ke dalam format JSON
    List<Map<String, dynamic>> jsonList =
    keranjangList.map((keranjang) => keranjang.toJson()).toList();

    // Menyimpan JSON ke dalam file
    await file.writeAsString(jsonEncode(jsonList));
  }

  // Mengambil data keranjang dari file JSON
  Future<List<Keranjang>> loadKeranjang() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();

      // Mengonversi JSON menjadi list objek Keranjang
      List<dynamic> jsonList = jsonDecode(contents);
      return jsonList
          .map((jsonItem) => Keranjang.fromJson(jsonItem))
          .toList();
    } catch (e) {
      // Jika file tidak ada atau error lainnya, return list kosong
      return [];
    }
  }

  // Menghapus file JSON (opsional, misalnya untuk reset data)
  Future<void> deleteKeranjang() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
