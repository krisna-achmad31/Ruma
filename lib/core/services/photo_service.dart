import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Mengambil foto lalu mengecilkannya jadi thumbnail base64 (sekitar 50 sampai 90 KB)
/// supaya bisa disimpan di Firestore tanpa Firebase Storage berbayar.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickBase64({bool fromCamera = true, double maxWidth = 720}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: 60,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  static String toDataUri(String base64) => 'data:image/jpeg;base64,$base64';

  static String? base64FromDataUri(String? uri) {
    if (uri == null || !uri.startsWith('data:image')) return null;
    final i = uri.indexOf(',');
    return i < 0 ? null : uri.substring(i + 1);
  }
}
