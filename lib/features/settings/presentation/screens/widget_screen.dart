import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Penjelasan dan pemasangan widget layar utama Android.
class WidgetScreen extends StatelessWidget {
  const WidgetScreen({super.key});

  Future<void> _pin(BuildContext context) async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (supported) {
        await HomeWidget.requestPinWidget(androidName: 'HomeSummaryWidgetProvider');
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      showSnack(context, tr('Tekan lama layar utama, pilih Widget, lalu cari widget aplikasi ini.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      tab: AppTab.rumah,
      bottom: PrimaryButton(label: tr('Pasang di layar utama'), icon: AppIcons.layoutGrid, onPressed: () => _pin(context)),
      children: [
        AppNavBar(title: tr('Widget layar utama')),
        Text(tr('Lihat yang penting tanpa buka aplikasi.'), style: AppText.display(26, height: 1.15)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFCFE3D9), Color(0xFFE9D6CF), Color(0xFFD8D2EA)]),
          ),
          child: GlassCard(
            strong: true,
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                    Text(tr('Aman dipakai'), style: AppText.body(11, color: AppColors.muted)),
                    Text(tr('Rp182rb'), style: AppText.display(20, color: AppColors.jade)),
                  ]),
                ),
                Pill(tr('Dinda 😮‍💨 2/5'), color: AppColors.rose, background: AppColors.roseSoft),
              ]),
              Row(children: [
                Expanded(child: Text(tr('Perlu dipikirkan'), style: AppText.body(13, weight: FontWeight.w700))),
                Text(tr('0/3 beres'), style: AppText.body(11, weight: FontWeight.w700, color: AppColors.jade)),
              ]),
              Text(tr('Galon habis\nBayar listrik PLN\nServis AC kamar'), style: AppText.body(12, color: AppColors.muted, height: 1.5)),
            ]),
          ),
        ),
        Text(
          tr('Contoh tampilan. Isi widget mengikuti data rumahmu dan diperbarui setiap kamu membuka Hari ini.'),
          style: AppText.body(13, color: AppColors.muted, height: 1.4),
        ),
        LabeledGroup(label: tr('Yang ditampilkan'), rows: [
          ListRow(icon: AppIcons.wallet, title: tr('Sisa uang aman hari ini'), subtitle: tr('Dari semua amplop sampai gajian')),
          ListRow(icon: AppIcons.heart, iconColor: AppColors.rose, iconBackground: AppColors.roseSoft, title: tr('Mood & energi pasangan'), subtitle: tr('Dari check-in 2 menit')),
          ListRow(icon: AppIcons.listChecks, title: tr('Urusan yang perlu dipikirkan'), subtitle: tr('Tiga urusan terdekat')),
        ]),
      ],
    );
  }
}
