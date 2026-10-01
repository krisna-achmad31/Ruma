import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/search_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<SearchViewModel>(
      create: (user) => SearchViewModel(
        financeRepository: buildFinanceRepository(),
        taskRepository: buildTaskRepository(),
        settingsRepository: buildSettingsRepository(),
        familyId: user.familyId,
        userName: user.name,
      ),
      child: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    final quick = vm.quickEntry;
    final hasResults = vm.transactionResults.isNotEmpty || vm.taskResults.isNotEmpty || vm.vaultResults.isNotEmpty;

    return AppScaffold(
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: GlassCard(
                strong: true,
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 10,
                  children: [
                    const Icon(AppIcons.search, size: 18, color: AppColors.muted),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: AppText.body(15),
                        onChanged: vm.setQuery,
                        decoration: InputDecoration(border: InputBorder.none, hintText: tr('Cari atau catat…'), hintStyle: AppText.body(15, color: AppColors.faint)),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          vm.setQuery('');
                        },
                        child: const Icon(AppIcons.circleX, size: 18, color: AppColors.faint),
                      ),
                  ],
                ),
              ),
            ),
            GestureDetector(onTap: () => context.pop(), child: Text(tr('Batal'), style: AppText.body(15, weight: FontWeight.w600, color: AppColors.jade))),
          ],
        ),
        if (quick != null)
          InfoBanner(
            icon: AppIcons.sparkles,
            color: AppColors.amber,
            background: AppColors.amberSoft,
            text: tr('Catat “{0} {1}”? Amplop dan dompetnya kami isi otomatis.', [quick.title, formatRupiahShort(quick.amount)]),
            trailing: GestureDetector(
              onTap: () async {
                await vm.recordQuickEntry();
                if (!context.mounted) return;
                showSnack(context, tr('{0} tercatat.', [quick.title]));
                _controller.clear();
                vm.setQuery('');
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(AppIcons.arrowUp, size: 16, color: Colors.white),
              ),
            ),
          ),
        if (vm.query.isEmpty)
          InfoBanner(icon: AppIcons.lightbulb, text: tr('Ketik seperti ngobrol, misalnya "bensin 50rb gopay", untuk langsung mencatat.'))
        else if (!hasResults && quick == null)
          GlassCard(child: EmptyNote(tr('Tidak ada yang cocok.'), icon: AppIcons.searchX)),
        if (vm.transactionResults.isNotEmpty)
          LabeledGroup(
            label: tr('Transaksi'),
            rows: vm.transactionResults
                .map((t) => ListRow(
                      icon: iconFor(vm.categoryOf(t.categoryId)?.icon ?? 'payments'),
                      iconColor: AppColors.amber,
                      iconBackground: AppColors.amberSoft,
                      title: t.title,
                      subtitle: '${formatShortDate(t.date)} · ${vm.categoryOf(t.categoryId)?.name ?? (t.isIncome ? tr('Pemasukan') : tr('Tanpa amplop'))}',
                      trailingText: formatRupiah(t.amount, withSign: t.isIncome),
                      trailingColor: t.isIncome ? AppColors.jade : AppColors.ink,
                    ))
                .toList(),
          ),
        if (vm.taskResults.isNotEmpty)
          LabeledGroup(
            label: tr('Urusan'),
            rows: vm.taskResults
                .map((t) => ListRow(
                      icon: AppIcons.listChecks,
                      title: t.title,
                      subtitle: t.dueDate == null ? tr('Tanpa tanggal') : relativeDayLabel(t.dueDate!),
                      onTap: () => context.go('/urusan'),
                    ))
                .toList(),
          ),
        if (vm.vaultResults.isNotEmpty)
          LabeledGroup(
            label: tr('Brankas'),
            rows: vm.vaultResults
                .map((v) => ListRow(icon: AppIcons.lockKeyhole, title: v.title, subtitle: tr('Buka dengan PIN'), onTap: () => context.push('/settings/important-links')))
                .toList(),
          ),
      ],
    );
  }
}
