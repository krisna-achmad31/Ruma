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
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _filters = ['Semua', 'Bank', 'E-wallet', 'Tunai'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Dompet'), actionIcon: AppIcons.plus, onAction: () => _addWallet(context, vm)),
        PastelHero(
          tone: PastelTone.sky,
          object: 'bank',
          objectSize: 104,
          objectRotation: 8,
          label: tr('Total semua dompet'),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            HeroNumber(formatRupiah(vm.householdMoney), size: 32),
            Text(
              vm.savingsMoney > 0
                  ? tr('{0} dompet. Belum termasuk tabungan {1}.', [vm.spendingWallets.length, formatRupiahShort(vm.savingsMoney)])
                  : tr('{0} dompet dipakai bersama.', [vm.spendingWallets.length]),
              style: AppText.body(13, color: AppColors.muted, height: 1.4),
            ),
          ]),
        ),
        SegmentedControl(labels: [for (final f in _filters) tr(f)], selected: _filters.indexOf(vm.walletFilter).clamp(0, 3), onChanged: (i) => vm.setWalletFilter(_filters[i])),
        ListCard(
          children: vm.filteredWallets.isEmpty
              ? [EmptyNote(tr('Belum ada dompet di kelompok ini.'))]
              : vm.filteredWallets.map((w) {
                  final savings = w.type == 'savings';
                  return ListRow(
                    icon: iconForWalletType(w.type),
                    iconColor: toneForWalletType(w.type).$1,
                    iconBackground: toneForWalletType(w.type).$2,
                    title: w.name,
                    subtitle: savings ? tr('Tabungan · tidak ikut dipakai') : '${walletTypeLabel(w.type)}${w.isDefault ? ' · dompet utama' : ''}',
                    trailingText: formatRupiah(w.balance),
                    trailingColor: savings ? AppColors.amber : AppColors.ink,
                  );
                }).toList(),
        ),
        PrimaryButton(label: tr('Pindah saldo'), secondary: true, icon: AppIcons.arrowLeftRight, onPressed: () => context.push('/finance/transfer')),
        SectionHeader(title: tr('Pindah saldo terakhir')),
        ListCard(
          children: vm.transfers.isEmpty
              ? [EmptyNote(tr('Belum ada pindah saldo.'))]
              : vm.transfers.take(5).map((t) {
                  final from = vm.walletById(t.fromWalletId)?.name ?? '?';
                  final to = vm.walletById(t.toWalletId)?.name ?? '?';
                  return ListRow(
                    icon: AppIcons.arrowLeftRight,
                    title: '$from → $to',
                    subtitle: tr('{0} · biaya {1}', [formatShortDate(t.date), formatRupiah(t.adminFee)]),
                    trailingText: formatRupiah(t.amount),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Future<void> _addWallet(BuildContext context, FinanceViewModel vm) async {
    final name = TextEditingController();
    final balance = TextEditingController();
    var type = 'bank';
    await showAppSheet<void>(
      context,
      title: tr('Dompet baru'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            AppTextField(controller: name, hint: tr('Misalnya: BCA, GoPay, Tunai'), autofocus: true),
            Wrap(
              spacing: 8,
              children: [('bank', tr('Bank')), ('ewallet', tr('E-wallet')), ('cash', tr('Tunai')), ('savings', tr('Tabungan'))]
                  .map((t) => ChoiceChip(label: Text(t.$2), selected: type == t.$1, onSelected: (_) => setState(() => type = t.$1), selectedColor: AppColors.jadeSoft))
                  .toList(),
            ),
            AppTextField(controller: balance, hint: tr('Saldo sekarang (Rp)'), keyboardType: TextInputType.number),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await vm.addWallet(name.text.trim(), type, double.tryParse(balance.text.replaceAll(RegExp(r'\D'), '')) ?? 0);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
