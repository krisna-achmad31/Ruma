import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/money_extras_entity.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Tabungan dan target (koleksi goals).
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _palette = [toneSky, toneJade, toneButter, toneLilac, toneRose];

  String _subtitle(GoalEntity g) {
    if (g.targetDate == null) return g.note.isEmpty ? tr('Tanpa tenggat') : g.note;
    final months = ((g.targetDate!.difference(DateTime.now()).inDays) / 30).ceil().clamp(1, 600);
    final perMonth = (g.targetAmount - g.currentAmount).clamp(0, double.infinity) / months;
    return tr('Target {0} {1} · sisihkan {2}/bulan', [shortMonthNamesId[g.targetDate!.month - 1], g.targetDate!.year, formatRupiahShort(perMonth)]);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final last = [...vm.goals.where((g) => g.lastDate != null)]..sort((a, b) => b.lastDate!.compareTo(a.lastDate!));

    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Tabungan'), actionIcon: AppIcons.plus, onAction: () => _add(context, vm)),
        SegmentedControl(
          labels: [tr('Belanja'), tr('Tabungan'), tr('Utang & aset')],
          selected: 1,
          onChanged: (i) {
            if (i == 0) context.pushReplacement('/finance/categories');
            if (i == 2) context.pushReplacement('/finance/assets');
          },
        ),
        if (vm.goals.isEmpty) GlassCard(child: EmptyNote(tr('Belum ada target tabungan. Tambah dengan tombol +.'), icon: AppIcons.piggyBank)),
        ...List.generate(vm.goals.length, (i) {
          final g = vm.goals[i];
          final tone = _palette[i % _palette.length];
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(spacing: 12, children: [
                  IconBox(icon: iconFor(g.icon), color: tone.$1, background: tone.$2, size: 42),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                      Text(g.name, style: AppText.body(16, weight: FontWeight.w700)),
                      Text(_subtitle(g), style: AppText.body(12, color: AppColors.muted)),
                    ]),
                  ),
                ]),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text(formatRupiah(g.currentAmount), style: AppText.display(22, letterSpacing: -0.5))),
                  Text(tr('dari {0}', [formatRupiah(g.targetAmount)]), style: AppText.body(12, color: AppColors.faint)),
                ]),
                ProgressBar(value: g.progress, color: tone.$1, height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      final v = await showAmountSheet(context, title: tr('Sisihkan ke {0}', [g.name]), initial: 500000, confirmLabel: tr('Sisihkan'));
                      if (v != null) await vm.contributeGoal(g, v);
                    },
                    child: Pill(tr('Sisihkan'), icon: AppIcons.plus, color: tone.$1, background: tone.$2),
                  ),
                ),
              ],
            ),
          );
        }),
        if (last.isNotEmpty)
          InfoBanner(
            icon: AppIcons.sparkles,
            text: '${tr('Terakhir: {0} +{1}', [last.first.name, formatRupiah(last.first.lastContribution)])}'
                '${last.first.lastContributorName == null ? '' : tr(' dari {0}', [last.first.lastContributorName!.split(' ').first])}'
                ', ${formatShortDate(last.first.lastDate!)}.',
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, FinanceViewModel vm) async {
    final name = await showTextSheet(context, title: tr('Target baru'), hint: tr('Misalnya: Liburan ke Bali'), confirmLabel: tr('Lanjut'));
    if (name == null || !context.mounted) return;
    final target = await showAmountSheet(context, title: tr('Target {0}', [name]), initial: 0, confirmLabel: tr('Lanjut'));
    if (target == null || !context.mounted) return;
    final date = await showDatePicker(
      context: context,
      helpText: tr('Kapan targetnya?'),
      initialDate: DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    await vm.addGoal(name, target, date);
  }
}
