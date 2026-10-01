import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class ReflectionHistoryScreen extends StatelessWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _labels = ['Paling disyukuri', 'Yang ingin diperbaiki', 'Keputusan terberat', 'Rencana bulan depan'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    final past = vm.pastReflections;
    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(title: tr('Riwayat')),
        InfoBanner(icon: AppIcons.info, color: AppColors.rose, background: AppColors.roseSoft, text: tr('Dibuka tiap tanggal 25 dan ditutup akhir bulan.')),
        if (past.isEmpty) GlassCard(child: EmptyNote(tr('Belum ada riwayat ngobrol akhir bulan.'), icon: AppIcons.history)),
        ...past.map((r) {
          final parts = r.monthKey.split('-');
          final label = parts.length == 2 ? '${monthNamesId[int.parse(parts[1]) - 1]} ${parts[0]}' : r.monthKey;
          final done = vm.isComplete(r);
          String preview = tr('Baru satu yang mengisi bulan ini.');
          if (done) {
            final mine = r.memberAnswers[vm.uid]?.answers ?? r.memberAnswers.values.first.answers;
            final idx = mine.indexWhere((a) => a != null && a.isNotEmpty);
            preview = idx >= 0 ? '${tr(_labels[idx % _labels.length])}: “${mine[idx]}”' : tr('Kalian berdua sudah mengisi.');
          }
          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
              Row(children: [
                Expanded(child: Text(label, style: AppText.body(16, weight: FontWeight.w700))),
                done ? Pill(tr('Dibaca bareng'), icon: AppIcons.check) : Pill(tr('Belum lengkap'), color: AppColors.muted, background: Color(0x0F15201D)),
              ]),
              Text(preview, style: AppText.body(13, color: AppColors.muted, height: 1.35)),
            ]),
          );
        }),
      ],
    );
  }
}
