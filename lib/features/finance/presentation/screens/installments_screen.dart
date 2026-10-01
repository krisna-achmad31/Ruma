import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class InstallmentsScreen extends StatelessWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final safe = vm.debtRatio <= 0.3;
    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Cicilan & paylater'), actionIcon: AppIcons.plus, onAction: () => _add(context, vm)),
        PastelHero(
          tone: PastelTone.butter,
          object: 'credit_card',
          objectSize: 104,
          objectRotation: -14,
          label: tr('Total cicilan bulan ini'),
          plus: true,
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            HeroNumber(formatRupiah(vm.installmentsMonthly), size: 32),
            Text(
              vm.monthlyIncomeEstimate <= 0
                  ? tr('Catat pemasukan dulu supaya rasio bisa dihitung')
                  : tr('{0}% dari pendapatan{1}. Batas aman 30%.', [(vm.debtRatio * 100).round(), safe ? tr(', masih aman') : tr(', lewat batas aman')]),
              style: AppText.body(13, color: AppColors.muted, height: 1.4),
            ),
          ]),
          body: HeroBar(value: vm.debtRatio / 0.5, tone: PastelTone.butter, color: safe ? AppColors.jade : AppColors.rose),
        ),
        SectionHeader(title: tr('Jatuh tempo')),
        ListCard(
          children: vm.installments.isEmpty
              ? [EmptyNote(tr('Belum ada cicilan atau paylater. Tambah dengan tombol +.'))]
              : vm.installments.map((i) {
                  final soon = i.nextDueDate.difference(DateTime.now()).inDays <= 7;
                  final color = soon ? AppColors.amber : AppColors.jade;
                  return InkWell(
                    onTap: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: tr('Sudah dibayar?'),
                        message: tr('{0} {1}. Cicilan ke-{2} dari {3}.', [i.name, formatRupiah(i.monthlyAmount), i.paidCount + 1, i.totalCount]),
                        confirmLabel: tr('Tandai lunas bulan ini'),
                        icon: AppIcons.calendarCheck,
                      );
                      if (ok) await vm.payInstallment(i);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(spacing: 12, children: [
                        IconBox(icon: AppIcons.creditCard, color: color, background: soon ? AppColors.amberSoft : AppColors.jadeSoft),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
                            Row(children: [
                              Expanded(child: Text(i.name, style: AppText.body(15, weight: FontWeight.w600))),
                              Text(formatRupiah(i.monthlyAmount), style: AppText.body(14, weight: FontWeight.w700)),
                            ]),
                            Row(children: [
                              Expanded(child: Text(tr('{0} · {1} dari {2}', [i.provider, i.paidCount, i.totalCount]), style: AppText.body(12, color: AppColors.muted))),
                              Text(formatShortDate(i.nextDueDate), style: AppText.body(12, weight: FontWeight.w700, color: color)),
                            ]),
                            ProgressBar(value: i.progress, color: color, height: 5),
                          ]),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
        ),
        InfoBanner(
          icon: AppIcons.lightbulb,
          color: AppColors.amber,
          background: AppColors.amberSoft,
          text: tr('Paylater bukan dana darurat. Lunasi yang bunganya paling tinggi dulu, lalu tahan paylater baru sampai cicilan lain selesai.'),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, FinanceViewModel vm) async {
    final name = TextEditingController();
    final provider = TextEditingController();
    final monthly = TextEditingController();
    final total = TextEditingController(text: '12');
    final paid = TextEditingController(text: '0');
    var due = DateTime.now().add(const Duration(days: 14));
    await showAppSheet<void>(
      context,
      title: tr('Cicilan baru'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            AppTextField(controller: name, hint: tr('Untuk apa, misalnya cicilan HP'), autofocus: true),
            AppTextField(controller: provider, hint: tr('Penyedia, misalnya Kredivo')),
            AppTextField(controller: monthly, hint: tr('Per bulan (Rp)'), keyboardType: TextInputType.number),
            Row(spacing: 10, children: [
              Expanded(child: LabeledField(label: tr('Sudah dibayar'), child: AppTextField(controller: paid, keyboardType: TextInputType.number))),
              Expanded(child: LabeledField(label: tr('Total bulan'), child: AppTextField(controller: total, keyboardType: TextInputType.number))),
            ]),
            ListRow(
              icon: AppIcons.calendar,
              title: formatLongDate(due),
              subtitle: tr('Jatuh tempo berikutnya'),
              chevron: true,
              onTap: () async {
                final p = await showDatePicker(context: context, initialDate: due, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime(2035));
                if (p != null) setState(() => due = p);
              },
            ),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                final m = double.tryParse(monthly.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
                if (name.text.trim().isEmpty || m <= 0) return;
                await vm.addInstallment(
                  name: name.text.trim(),
                  provider: provider.text.trim().isEmpty ? tr('Cicilan') : provider.text.trim(),
                  monthly: m,
                  due: due,
                  total: int.tryParse(total.text) ?? 12,
                  paid: int.tryParse(paid.text) ?? 0,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
