import 'package:home_widget/home_widget.dart';

import '../l10n/app_locale.dart';

/// Mengirim ringkasan ke widget layar utama Android (HomeSummaryWidgetProvider).
class HomeWidgetService {
  static const _androidProvider = 'HomeSummaryWidgetProvider';

  static Future<void> update({
    required String safeToSpend,
    required String partnerMood,
    required String tasksLine,
    required String tasksCount,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('safe_to_spend', safeToSpend);
      await HomeWidget.saveWidgetData<String>('partner_mood', partnerMood);
      await HomeWidget.saveWidgetData<String>('tasks_line', tasksLine);
      await HomeWidget.saveWidgetData<String>('tasks_count', tasksCount);
      // Label ikut bahasa aplikasi, bukan bahasa perangkat.
      await HomeWidget.saveWidgetData<String>('label_safe', tr('Aman dipakai'));
      await HomeWidget.saveWidgetData<String>('label_tasks', tr('Perlu dipikirkan'));
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // Widget belum dipasang di layar utama, tidak masalah.
    }
  }
}
