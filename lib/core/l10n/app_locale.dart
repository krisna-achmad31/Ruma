import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_en.dart';

/// Bahasa aplikasi, disimpan per perangkat supaya pasangan boleh beda bahasa.
/// Teks sumber ditulis dalam bahasa Indonesia dan dipakai sebagai kunci terjemahan.
class AppLocale extends ChangeNotifier {
  AppLocale._();

  static final AppLocale instance = AppLocale._();

  static const supported = ['id', 'en'];
  static const _prefKey = 'app_language';

  String _code = 'id';

  String get code => _code;

  bool get isEn => _code == 'en';

  Locale get locale => Locale(_code);

  /// Dipanggil sekali sebelum runApp. Tanpa pilihan tersimpan, ikuti bahasa perangkat.
  Future<void> load() async {
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(_prefKey);
    } catch (_) {
      saved = null;
    }
    final device = PlatformDispatcher.instance.locale.languageCode;
    _code = supported.contains(saved) ? saved! : (device == 'id' || device == 'ms' ? 'id' : 'en');
  }

  Future<void> setCode(String code) async {
    if (!supported.contains(code) || code == _code) return;
    _code = code;
    try {
      await (await SharedPreferences.getInstance()).setString(_prefKey, code);
    } catch (_) {}
    notifyListeners();
    _rebuildAll();
  }

  /// Teks yang dibaca lewat tr() tidak terikat ke widget tertentu, jadi seluruh
  /// pohon widget dibangun ulang supaya bahasa baru langsung terlihat.
  void _rebuildAll() {
    void mark(Element el) {
      el.markNeedsBuild();
      el.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}

/// Terjemahkan teks sumber berbahasa Indonesia. Tanda {0}, {1}, dan seterusnya
/// diganti dengan [args] sesuai urutan. Teks tanpa terjemahan tampil apa adanya.
/// Kata yang maknanya bergantung konteks diberi penanda setelah garis tegak,
/// misalnya 'Masuk|uang', dan penanda itu tidak ikut tampil.
String tr(String source, [List<Object?> args = const []]) {
  final en = AppLocale.instance.isEn;
  final bar = source.indexOf('|');
  var text = en ? (stringsEn[source] ?? (bar < 0 ? source : source.substring(0, bar))) : (bar < 0 ? source : source.substring(0, bar));
  for (int i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i] ?? ''}');
  }
  // Bahasa Inggris membedakan tunggal dan jamak: "1 day", bukan "1 days".
  if (en && args.isNotEmpty) text = text.replaceAllMapped(_singular, (m) => m[2] == 'people' ? '${m[1]}person' : '${m[1]}${m[2]!.substring(0, m[2]!.length - 1)}');
  return text;
}

final _singular = RegExp(r'(\b1 )(days|hours|minutes|weeks|months|years|members|wallets|tasks|bills|moments|items|people)\b');
