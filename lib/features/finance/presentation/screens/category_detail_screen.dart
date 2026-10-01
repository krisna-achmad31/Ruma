import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/category_entity.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) => FinanceScope(child: _Content(categoryId: categoryId));
}

class _Content extends StatelessWidget {
  final String categoryId;

  const _Content({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final c = vm.categoryById(categoryId);
    if (c == null) {
      return AppScaffold(tab: AppTab.uang, children: [AppNavBar(title: tr('Amplop')), GlassCard(child: EmptyNote(tr('Amplop tidak ditemukan.')))]);
    }
    final change = vm.changeVsLastMonth(c.id);
    final wallet = vm.walletById(c.walletId);
    final txs = vm.transactionsOf(c.id).take(5).toList();

    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: c.name, actionIcon: AppIcons.ellipsis, onAction: () => _rename(context, vm, c)),
        PastelHero(
          tone: PastelTone.of(vm.isLow(c) ? (AppColors.amber, AppColors.amberSoft) : toneForCategory(c.icon, c.name)),
          object: AppIcons.objectNameFor(iconFor(c.icon), 'envelope'),
          label: tr('{0}, sisa', [c.name]),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            HeroNumber(formatRupiahShort(vm.remainingOf(c)), size: 44),
            Text(tr('dari {0}. Aman dipakai {1} per hari sampai gajian.', [formatRupiahShort(c.budgetAmount), formatRupiahShort(vm.safePerDay(c))]), style: AppText.body(13, color: AppColors.muted, height: 1.4)),
          ]),
          body: HeroBar(value: vm.remainingFractionOf(c), tone: PastelTone.of(toneForCategory(c.icon, c.name)), color: vm.isLow(c) ? AppColors.amber : null),
        ),
        Row(
          spacing: 8,
          children: [
            _Action(icon: AppIcons.pencil, label: tr('Ubah nama'), onTap: () => _rename(context, vm, c)),
            _Action(icon: AppIcons.landmark, label: tr('Dompet'), onTap: () => _pickWallet(context, vm, c)),
            _Action(icon: AppIcons.slidersHorizontal, label: tr('Anggaran'), onTap: () => _budget(context, vm, c)),
          ],
        ),
        if (change != null)
          InfoBanner(
            icon: change >= 0 ? AppIcons.trendingUp : AppIcons.trendingDown,
            color: change >= 0 ? AppColors.rose : AppColors.jade,
            background: change >= 0 ? AppColors.roseSoft : AppColors.jadeSoft,
            text: tr('{0} {1}% dari bulan lalu.', [change >= 0 ? tr('Naik') : tr('Turun'), change.abs().round()]),
          ),
        SectionHeader(title: tr('Rincian'), action: tr('+ Tambah'), onAction: () async {
          final name = await showTextSheet(context, title: tr('Rincian baru'), hint: tr('Misalnya: Galon & gas'));
          if (name != null) await vm.addSubCategory(c.id, name);
        }),
        ListCard(
          children: c.subCategories.isEmpty
              ? [EmptyNote(tr('Belum ada rincian untuk amplop ini.'))]
              : c.subCategories.map((s) => ListRow(icon: iconFor(c.icon), title: s.name, trailingText: formatRupiahShort(s.amount))).toList(),
        ),
        if (txs.isNotEmpty)
          LabeledGroup(
            label: tr('Transaksi amplop ini'),
            rows: txs.map((t) => ListRow(title: t.title, subtitle: formatShortDate(t.date), trailingText: formatRupiah(t.amount))).toList(),
          ),
        Text(tr('Dompet utama amplop ini: {0}', [wallet?.name ?? tr('belum dipilih')]), style: AppText.body(12, color: AppColors.muted)),
      ],
    );
  }

  Future<void> _rename(BuildContext context, FinanceViewModel vm, CategoryEntity c) async {
    final name = await showTextSheet(context, title: tr('Ubah nama'), initial: c.name);
    if (name != null) await vm.renameCategory(c.id, name);
  }

  Future<void> _budget(BuildContext context, FinanceViewModel vm, CategoryEntity c) async {
    final value = await showAmountSheet(
      context,
      title: tr('Anggaran {0}', [c.name]),
      initial: c.budgetAmount,
      caption: tr('per bulan · terisi ulang tanggal {0}', [vm.resetDay]),
      hint: c.spentAmount > 0 ? tr('Terpakai bulan ini: {0}.', [formatRupiah(c.spentAmount)]) : null,
      confirmLabel: tr('Simpan anggaran'),
    );
    if (value != null) await vm.updateCategoryBudget(c.id, value);
  }

  Future<void> _pickWallet(BuildContext context, FinanceViewModel vm, CategoryEntity c) async {
    final w = await showPickerSheet(
      context,
      title: tr('Pilih dompet'),
      items: vm.spendingWallets,
      label: (w) => w.name,
      sublabel: (w) => tr('Saldo {0}', [formatRupiah(w.balance)]),
      icon: (w) => iconForWalletType(w.type),
      selected: vm.walletById(c.walletId),
    );
    if (w != null) await vm.setCategoryWallet(c.id, w.id);
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Column(spacing: 6, children: [
          Icon(icon, size: 18, color: AppColors.jade),
          Text(label, style: AppText.body(12, weight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
