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
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Amplop: anggaran per kategori, terisi ulang tiap tanggal gajian.
class CategoryBudgetScreen extends StatelessWidget {
  const CategoryBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final spentFraction = vm.budgetTotal <= 0 ? 0.0 : 1 - vm.budgetRemaining / vm.budgetTotal;
    final suggestion = vm.rebalanceSuggestion;

    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Amplop'), actionIcon: AppIcons.plus, onAction: () => _addCategory(context, vm)),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                    Text(tr('Sisa anggaran {0}', [monthNamesId[DateTime.now().month - 1]]), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
                    Text(formatRupiah(vm.budgetRemaining), style: AppText.display(28, letterSpacing: -0.8)),
                  ]),
                ),
                Text(tr('dari {0}', [formatRupiahShort(vm.budgetTotal)]), style: AppText.body(13, color: AppColors.muted)),
              ]),
              ProgressBar(value: 1 - spentFraction, height: 8),
              Text(tr('Amplop terisi ulang tiap tanggal {0}, pas gajian.', [vm.resetDay]), style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
        ),
        SegmentedControl(
          labels: [tr('Belanja'), tr('Tabungan'), tr('Utang & aset')],
          selected: 0,
          onChanged: (i) {
            if (i == 1) context.pushReplacement('/finance/goals');
            if (i == 2) context.pushReplacement('/finance/assets');
          },
        ),
        ListCard(
          children: vm.categories.isEmpty
              ? [EmptyNote(tr('Belum ada amplop. Tambah dengan tombol + di atas.'))]
              : vm.categories.map((c) {
                  final low = vm.isLow(c);
                  final color = low ? AppColors.amber : AppColors.jade;
                  return InkWell(
                    onTap: () => context.push('/finance/category/${c.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        spacing: 12,
                        children: [
                          Builder(builder: (_) {
                            final t = toneForCategory(c.icon, c.name);
                            return IconBox(icon: iconFor(c.icon), color: t.$1, background: t.$2);
                          }),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(c.name, style: AppText.body(15, weight: FontWeight.w600))),
                                  Text(formatRupiahShort(vm.remainingOf(c)), style: AppText.body(14, weight: FontWeight.w700, color: low ? AppColors.amber : AppColors.ink)),
                                ]),
                                ProgressBar(value: vm.remainingFractionOf(c), color: color),
                                Text(tr('sisa dari {0}', [formatRupiahShort(c.budgetAmount)]), style: AppText.body(11, color: AppColors.faint)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
        ),
        if (suggestion != null)
          InfoBanner(
            icon: AppIcons.lightbulb,
            color: AppColors.amber,
            background: AppColors.amberSoft,
            text: tr('{0} hampir habis. Pindahkan dari {1} yang masih longgar?', [suggestion.$1.name, suggestion.$2.name]),
          ),
      ],
    );
  }

  Future<void> _addCategory(BuildContext context, FinanceViewModel vm) async {
    final name = await showTextSheet(context, title: tr('Amplop baru'), hint: tr('Misalnya: Kesehatan'), confirmLabel: tr('Lanjut'));
    if (name == null || !context.mounted) return;
    final budget = await showAmountSheet(context, title: tr('Anggaran {0}', [name]), initial: 0, caption: tr('per bulan'), confirmLabel: tr('Buat amplop'));
    if (budget != null) await vm.addCategory(name, budget);
  }
}
