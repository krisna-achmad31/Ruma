import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/transaction_entity.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class FinanceReportScreen extends StatelessWidget {
  const FinanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  int _period = 2;

  List<TransactionEntity> _inPeriod(FinanceViewModel vm) {
    final now = DateTime.now();
    final today = dateOnly(now);
    return vm.transactions.where((t) {
      switch (_period) {
        case 0:
          return isSameDay(t.date, now);
        case 1:
          return !t.date.isBefore(today.subtract(Duration(days: now.weekday - 1)));
        case 3:
          return t.date.year == now.year;
        default:
          return t.date.year == now.year && t.date.month == now.month;
      }
    }).toList();
  }

  void _share(FinanceViewModel vm, int count) {
    final month = monthNamesId[DateTime.now().month - 1];
    final kept = vm.categories.where((c) => c.spentAmount <= c.budgetAmount).length;
    SharePlus.instance.share(ShareParams(
      text: '${tr('Rekap {0} kami di {1}: {2} transaksi tercatat bareng, {3} dari {4} amplop terjaga.', [month, AppBrand.name, count, kept, vm.categories.length])} '
          '${tr(AppBrand.taglineId)}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final list = _inPeriod(vm);
    final income = list.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());
    final expense = list.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());
    final report = vm.monthlyReport;
    final trend = vm.trend;
    final maxTrend = trend.isEmpty ? 1.0 : trend.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    final netWorth = report?.totalWealth ?? vm.netWorth;
    final now = DateTime.now();

    final metrics = [
      (tr('Pemasukan'), income, AppIcons.arrowDownLeft, AppColors.jade, AppColors.jadeSoft),
      (tr('Pengeluaran'), expense, AppIcons.arrowUpRight, AppColors.rose, AppColors.roseSoft),
      (tr('Investasi'), report?.investmentContribution ?? vm.investmentTotal, AppIcons.sprout, AppColors.amber, AppColors.amberSoft),
      (tr('Saldo akhir'), income - expense, AppIcons.wallet, AppColors.jade, AppColors.jadeSoft),
    ];

    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Rekap'), actionIcon: AppIcons.share2, onAction: () => _share(vm, list.length)),
        SegmentedControl(labels: [tr('Hari'), tr('Minggu'), tr('Bulan'), tr('Tahun')], selected: _period, onChanged: (i) => setState(() => _period = i)),
        HeroCard(
          colors: AppColors.jadeGradient,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(tr('Kekayaan bersih · {0} {1}', [monthNamesId[now.month - 1], now.year]), style: AppText.body(13, weight: FontWeight.w600, color: const Color(0xCCFFFFFF))),
              Text(formatRupiah(netWorth), style: AppText.display(34, color: Colors.white, letterSpacing: -1.1)),
              if (report != null && report.wealthChangePercent != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
                    Icon(report.wealthChangePercent >= 0 ? AppIcons.trendingUp : AppIcons.trendingDown, size: 13, color: Colors.white),
                    Text(tr('{0}{1}% dari bulan lalu', [report.wealthChangePercent >= 0 ? '+' : '', report.wealthChangePercent.toStringAsFixed(1).replaceAll('.', ',')]),
                        style: AppText.body(12, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              Text(tr('Kas {0} · Investasi {1}', [formatRupiahShort(report?.cash ?? vm.totalAllWallets), formatRupiahShort(report?.investment ?? vm.investmentTotal)]),
                  style: AppText.body(12, color: const Color(0xB3FFFFFF))),
            ],
          ),
        ),
        for (int i = 0; i < 4; i += 2)
          Row(
            spacing: 10,
            children: metrics
                .skip(i)
                .take(2)
                .map((m) => Expanded(
                      child: GlassCard(
                        radius: 20,
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                          IconBox(icon: m.$3, color: m.$4, background: m.$5, size: 32),
                          Text(m.$1, style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted)),
                          Text(formatRupiahShort(m.$2), style: AppText.display(20, letterSpacing: -0.4)),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        if (trend.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Row(children: [
                  Expanded(child: Text(tr('Tren 6 bulan'), style: AppText.body(15, weight: FontWeight.w700))),
                  Text(tr('kekayaan bersih'), style: AppText.body(12, color: AppColors.muted)),
                ]),
                SizedBox(
                  height: 130,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 10,
                    children: List.generate(trend.length, (i) {
                      final last = i == trend.length - 1;
                      return Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, spacing: 6, children: [
                          Container(
                            height: 108 * (trend[i].$2 / maxTrend),
                            decoration: BoxDecoration(color: last ? AppColors.jade : const Color(0x332C6B5A), borderRadius: BorderRadius.circular(8)),
                          ),
                          Text(trend[i].$1, style: AppText.body(11, weight: last ? FontWeight.w700 : FontWeight.w500, color: last ? AppColors.ink : AppColors.muted)),
                        ]),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => _share(vm, list.length),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(24)),
            child: Row(spacing: 12, children: [
              const IconBox(icon: AppIcons.sparkles, color: AppColors.rose, background: Color(0xB3FFFFFF), size: 40),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr('Kartu rekap {0} siap', [monthNamesId[now.month - 1]]), style: AppText.body(14, weight: FontWeight.w700)),
                  Text(tr('Aman dibagikan, tanpa angka pribadi'), style: AppText.body(12, color: AppColors.muted)),
                ]),
              ),
              const Icon(AppIcons.chevronRight, size: 18, color: AppColors.rose),
            ]),
          ),
        ),
      ],
    );
  }
}
