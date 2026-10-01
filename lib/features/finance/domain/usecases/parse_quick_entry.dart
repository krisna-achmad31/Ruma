import '../entities/category_entity.dart';
import '../entities/wallet_entity.dart';

/// Hasil membaca kalimat seperti "beli sayur 45rb pakai gopay".
class QuickEntry {
  final String title;
  final double amount;
  final bool isIncome;
  final String? walletId;
  final String? categoryId;

  const QuickEntry({required this.title, required this.amount, required this.isIncome, this.walletId, this.categoryId});
}

/// Membaca nominal, dompet, dan amplop dari teks bebas. Berjalan di perangkat, tanpa AI.
class ParseQuickEntry {
  static const _incomeWords = ['gaji', 'terima', 'dapat', 'bonus', 'thr', 'masuk', 'transfer dari', 'refund'];

  static const _categoryKeywords = <String, List<String>>{
    'makan': ['sayur', 'lauk', 'makan', 'beras', 'pasar', 'galon', 'gas', 'telur', 'ayam', 'jajan', 'kopi', 'belanja'],
    'rumah': ['listrik', 'token', 'pln', 'air', 'pdam', 'internet', 'wifi', 'sewa', 'kontrakan'],
    'transport': ['bensin', 'ojek', 'grab', 'gojek', 'parkir', 'tol', 'kereta', 'bus'],
    'anak': ['sekolah', 'spp', 'les', 'buku', 'seragam', 'susu', 'popok'],
    'hiburan': ['nonton', 'bioskop', 'netflix', 'spotify', 'langganan', 'game'],
  };

  QuickEntry? call(String input, {required List<WalletEntity> wallets, required List<CategoryEntity> categories}) {
    final text = input.toLowerCase().trim();
    if (text.isEmpty) return null;

    final amount = parseAmount(text);
    if (amount == null || amount <= 0) return null;

    final isIncome = _incomeWords.any(text.contains);

    String? walletId;
    for (final w in wallets) {
      if (w.name.isNotEmpty && text.contains(w.name.toLowerCase())) {
        walletId = w.id;
        break;
      }
    }
    walletId ??= wallets.where((w) => w.isDefault).map((w) => w.id).firstOrNull ?? wallets.firstOrNull?.id;

    String? categoryId;
    if (!isIncome) {
      for (final c in categories) {
        if (c.name.isNotEmpty && text.contains(c.name.toLowerCase())) {
          categoryId = c.id;
          break;
        }
      }
      if (categoryId == null) {
        for (final entry in _categoryKeywords.entries) {
          if (entry.value.any(text.contains)) {
            categoryId = categories
                .where((c) => c.name.toLowerCase().contains(entry.key) || entry.value.any((k) => c.name.toLowerCase().contains(k)))
                .map((c) => c.id)
                .firstOrNull;
            if (categoryId != null) break;
          }
        }
      }
    }

    var cleaned = input;
    for (final w in wallets) {
      if (w.name.isNotEmpty) cleaned = cleaned.replaceAll(RegExp(RegExp.escape(w.name), caseSensitive: false), '');
    }
    return QuickEntry(title: _cleanTitle(cleaned), amount: amount, isIncome: isIncome, walletId: walletId, categoryId: categoryId);
  }

  /// Mengenali "45rb", "45 ribu", "1,5jt", "1.5 juta", "86000", "86.000".
  static double? parseAmount(String text) {
    final match = RegExp(r'(\d+(?:[.,]\d+)*)\s*(rb|ribu|k|jt|juta)?\b').allMatches(text).toList();
    if (match.isEmpty) return null;
    final m = match.last;
    final raw = m.group(1)!;
    final unit = m.group(2);
    double value;
    if (unit == null) {
      value = double.tryParse(raw.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    } else {
      value = double.tryParse(raw.replaceAll('.', ',').replaceAll(',', '.')) ?? 0;
      if (unit == 'rb' || unit == 'ribu' || unit == 'k') value *= 1000;
      if (unit == 'jt' || unit == 'juta') value *= 1000000;
    }
    return value;
  }

  static String _cleanTitle(String input) {
    var t = input
        .replaceAll(RegExp(r'\d+(?:[.,]\d+)*\s*(rb|ribu|k|jt|juta)?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(pakai|pake|via|dari|ke|di|beli|bayar)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (t.isEmpty) return 'Transaksi';
    return t[0].toUpperCase() + t.substring(1);
  }
}
