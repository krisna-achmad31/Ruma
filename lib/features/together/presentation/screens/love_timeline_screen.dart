import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Perjalanan kita: momen manual dan momen yang tercatat otomatis dari kebiasaan.
class LoveTimelineScreen extends StatelessWidget {
  const LoveTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    final moments = vm.loveTimeline;
    final first = moments.isEmpty ? null : moments.last.date;
    final autoCount = moments.where((m) => m.auto).length;

    String since() {
      if (first == null) return tr('Mulai catat momen pertama kalian');
      final now = DateTime.now();
      var years = now.year - first.year;
      var months = now.month - first.month;
      if (now.day < first.day) months--;
      if (months < 0) {
        years--;
        months += 12;
      }
      return [if (years > 0) tr('{0} tahun', [years]), if (months > 0) tr('{0} bulan', [months])].join(' ').ifEmpty(tr('Baru mulai'));
    }

    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(title: tr('Perjalanan kita'), actionIcon: AppIcons.plus, onAction: () => _add(context, vm)),
        HeroCard(
          colors: AppColors.roseGradient,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            Text(first == null ? tr('Perjalanan kalian') : tr('Bersama sejak {0} {1} {2}', [first.day, monthNamesId[first.month - 1], first.year]),
                style: AppText.body(13, weight: FontWeight.w600, color: const Color(0xCCFFFFFF))),
            Text(since(), style: AppText.display(30, color: Colors.white, letterSpacing: -0.8)),
            Text(tr('{0} momen tercatat, {1} di antaranya otomatis dari kebiasaan kalian.', [moments.length, autoCount]), style: AppText.body(12, color: const Color(0xB3FFFFFF))),
          ]),
        ),
        if (moments.isEmpty)
          GlassCard(child: EmptyNote(tr('Belum ada momen. Tambah dengan tombol +.'), icon: AppIcons.milestone))
        else
          Column(
            children: List.generate(moments.length, (i) {
              final m = moments[i];
              final color = m.auto ? AppColors.amber : AppColors.rose;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Column(children: [
                        const SizedBox(height: 18),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        ),
                        if (i < moments.length - 1) Expanded(child: Container(width: 2, color: const Color(0x33B9536B))),
                      ]),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.all(14),
                          child: Row(spacing: 12, children: [
                            IconBox(icon: iconFor(m.icon), color: color, background: m.auto ? AppColors.amberSoft : AppColors.roseSoft, size: 36),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
                                Text(formatFullDate(m.date), style: AppText.body(11, weight: FontWeight.w700, color: AppColors.faint)),
                                Text(m.title, style: AppText.body(14, weight: FontWeight.w600)),
                                if (m.auto)
                                  Row(spacing: 4, children: [
                                    const Icon(AppIcons.sparkles, size: 11, color: AppColors.amber),
                                    Text(tr('tercatat otomatis'), style: AppText.body(11, weight: FontWeight.w600, color: AppColors.amber)),
                                  ]),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, TogetherViewModel vm) async {
    final title = await showTextSheet(context, title: tr('Momen baru'), hint: tr('Misalnya: Kia masuk TK'), confirmLabel: tr('Lanjut'));
    if (title == null || !context.mounted) return;
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1990), lastDate: DateTime.now(), helpText: tr('Kapan terjadinya?'));
    await vm.addMoment(title, date ?? DateTime.now());
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
