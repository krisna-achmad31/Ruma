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

class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final month = vm.selectedMonth;
    final recent = vm.transactions.take(4).toList();

    return AppScaffold(
      tab: AppTab.uang,
      children: [
        LargeTitle(
          title: tr('Uang'),
          trailing: GestureDetector(
            onTap: () async {
              final picked = await showPickerSheet<int>(
                context,
                title: tr('Pilih bulan'),
                items: List.generate(6, (i) => -i),
                label: (d) {
                  final m = DateTime(DateTime.now().year, DateTime.now().month + d);
                  return '${monthNamesId[m.month - 1]} ${m.year}';
                },
              );
              if (picked != null) {
                final now = DateTime.now();
                final target = DateTime(now.year, now.month + picked);
                vm.changeMonth((target.year - month.year) * 12 + target.month - month.month);
              }
            },
            child: GlassCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(spacing: 6, children: [
                Text(monthNamesId[month.month - 1], style: AppText.body(13, weight: FontWeight.w600)),
                const Icon(AppIcons.chevronDown, size: 14),
              ]),
            ),
          ),
        ),
        _HouseholdCard(vm: vm),
        _WalletStrip(vm: vm),
        Row(
          spacing: 8,
          children: [
            ShortcutTile(label: tr('Amplop'), icon: AppIcons.mails, tone: toneAmber, onTap: () => context.push('/finance/categories')),
            ShortcutTile(label: tr('Dompet'), icon: AppIcons.landmark, tone: toneSky, onTap: () => context.push('/finance/wallets')),
            ShortcutTile(label: tr('Tabungan'), icon: AppIcons.piggyBank, tone: toneButter, onTap: () => context.push('/finance/goals')),
            ShortcutTile(label: tr('Rekap'), icon: AppIcons.chartColumn, tone: toneLilac, onTap: () => context.push('/finance/report')),
          ],
        ),
        SectionHeader(title: tr('Transaksi terbaru'), action: tr('Catat'), onAction: () => context.push('/finance/add')),
        ListCard(
          children: recent.isEmpty
              ? [EmptyNote(tr('Belum ada transaksi. Catat yang pertama lewat tombol Catat.'))]
              : recent.map((t) {
                  final c = vm.categoryById(t.categoryId);
                  final who = t.createdByName == null ? '' : tr(' · dicatat {0}', [t.createdByName!.split(' ').first]);
                  return ListRow(
                    icon: t.isIncome ? AppIcons.briefcase : iconFor(c?.icon ?? 'payments'),
                    iconColor: t.isIncome ? AppColors.jade : AppColors.amber,
                    iconBackground: t.isIncome ? AppColors.jadeSoft : AppColors.amberSoft,
                    title: t.title,
                    subtitle: '${c?.name ?? (t.isIncome ? tr('Masuk ke {0}', [vm.walletById(t.walletId)?.name ?? tr('dompet')]) : tr('Tanpa amplop'))}$who',
                    trailingText: formatRupiah(t.amount, withSign: t.isIncome),
                    trailingColor: t.isIncome ? AppColors.jade : AppColors.ink,
                  );
                }).toList(),
        ),
        _EnvelopeGrid(vm: vm),
        _InstallmentCard(vm: vm),
        _WishlistCard(vm: vm),
      ],
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  final FinanceViewModel vm;

  const _HouseholdCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      colors: AppColors.jadeGradient,
      padding: const EdgeInsets.all(20),
      onTap: () => context.push('/finance/wallets'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(children: [
            Expanded(child: Text(tr('Uang rumah'), style: AppText.body(14, weight: FontWeight.w600, color: const Color(0xCCFFFFFF)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x40FFFFFF))),
              child: Text(tr('{0} dompet', [vm.spendingWallets.length]), style: AppText.body(11, weight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
          Text(formatRupiah(vm.householdMoney), style: AppText.display(38, color: Colors.white, letterSpacing: -1.3)),
          Row(
            spacing: 10,
            children: [
              for (final s in [(tr('Masuk|uang'), vm.monthIncome, AppIcons.arrowDownLeft), (tr('Keluar|uang'), vm.monthExpense, AppIcons.arrowUpRight)])
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16)),
                    child: Row(spacing: 10, children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
                        child: Icon(s.$3, size: 15, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                          Text(s.$1, style: AppText.body(11, color: const Color(0xB3FFFFFF))),
                          Text(formatRupiahShort(s.$2), style: AppText.body(15, weight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  final FinanceViewModel vm;

  const _WalletStrip({required this.vm});

  @override
  Widget build(BuildContext context) {
    final shown = vm.spendingWallets.take(3).toList();
    final extra = vm.wallets.length - shown.length;
    if (shown.isEmpty) return const SizedBox.shrink();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          ...shown.map((w) => Expanded(
                child: GlassCard(
                  radius: 18,
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.push('/finance/wallets'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                    IconBox(icon: iconForWalletType(w.type), size: 30, color: toneForWalletType(w.type).$1, background: toneForWalletType(w.type).$2),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                      Text(w.name, style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(formatRupiahShort(w.balance), style: AppText.body(14, weight: FontWeight.w700)),
                    ]),
                  ]),
                ),
              )),
          if (extra > 0)
            SizedBox(
              width: 56,
              child: GlassCard(
                radius: 18,
                padding: EdgeInsets.zero,
                onTap: () => context.push('/finance/wallets'),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 2, children: [
                  Text('+$extra', style: AppText.body(15, weight: FontWeight.w700, color: AppColors.jade)),
                  Text(tr('lagi'), style: AppText.body(10, color: AppColors.muted)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnvelopeGrid extends StatelessWidget {
  final FinanceViewModel vm;

  const _EnvelopeGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cats = vm.categories.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(
          title: tr('Amplop'),
          trailing: Text(tr('Sisa {0}', [formatRupiahShort(vm.budgetRemaining)]), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
        ),
        if (cats.isEmpty)
          GlassCard(onTap: () => context.push('/finance/categories'), child: EmptyNote(tr('Belum ada amplop. Buat amplop pertama di halaman Amplop.')))
        else
          for (int i = 0; i < cats.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  for (final c in cats.skip(i).take(2))
                    Expanded(
                      child: GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.all(16),
                        onTap: () => context.push('/finance/category/${c.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            IconBox(
                              icon: iconFor(c.icon),
                              size: 34,
                              color: toneForCategory(c.icon, c.name).$1,
                              background: toneForCategory(c.icon, c.name).$2,
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                              Text(c.name, style: AppText.body(13, weight: FontWeight.w600)),
                              Text(formatRupiahShort(vm.remainingOf(c)), style: AppText.display(18, color: vm.isLow(c) ? AppColors.amber : AppColors.ink)),
                              Text(tr('sisa dari {0}', [formatRupiahShort(c.budgetAmount)]), style: AppText.body(11, color: AppColors.faint)),
                            ]),
                            ProgressBar(value: vm.remainingFractionOf(c), color: vm.isLow(c) ? AppColors.amber : AppColors.jade),
                          ],
                        ),
                      ),
                    ),
                  if (cats.skip(i).length == 1) const Expanded(child: SizedBox()),
                ],
              ),
            ),
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  final FinanceViewModel vm;

  const _InstallmentCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final next = vm.installments.firstOrNull;
    final safe = vm.debtRatio <= 0.3;
    return GlassCard(
      onTap: () => context.push('/finance/installments'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(spacing: 10, children: [
            const IconBox(icon: AppIcons.calendarClock, color: AppColors.amber, background: AppColors.amberSoft),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                Text(tr('Cicilan & paylater'), style: AppText.body(15, weight: FontWeight.w700)),
                Text(
                  vm.installments.isEmpty ? tr('Belum ada cicilan tercatat') : tr('{0} tagihan · {1} bulan ini', [vm.installments.length, formatRupiahShort(vm.installmentsMonthly)]),
                  style: AppText.body(12, color: AppColors.muted),
                ),
              ]),
            ),
            const PlusBadge(),
          ]),
          if (vm.installments.isNotEmpty) ...[
            ProgressBar(value: vm.debtRatio / 0.5, color: safe ? AppColors.jade : AppColors.rose, height: 8),
            Row(children: [
              Expanded(
                child: Text(
                  tr('{0}% dari pendapatan{1}', [(vm.debtRatio * 100).round(), safe ? tr(', masih aman') : tr(', lewat batas aman')]),
                  style: AppText.body(12, weight: FontWeight.w700, color: safe ? AppColors.jade : AppColors.rose),
                ),
              ),
              Text(tr('batas 30%'), style: AppText.body(12, color: AppColors.faint)),
            ]),
          ],
          if (next != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Expanded(child: Text('${next.provider}, ${next.name.toLowerCase()} ${next.paidCount + 1}/${next.totalCount}', style: AppText.body(13, weight: FontWeight.w500))),
                Text(tr('Jatuh tempo {0}', [formatShortDate(next.nextDueDate)]), style: AppText.body(12, weight: FontWeight.w700, color: AppColors.amber)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final FinanceViewModel vm;

  const _WishlistCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(title: tr('Tunda 48 jam'), action: tr('Tambah'), onAction: () => _add(context)),
        if (vm.wishlist.isEmpty)
          GlassCard(child: EmptyNote(tr('Mau beli sesuatu yang nggak mendesak? Tahan dulu 48 jam di sini.'), icon: AppIcons.hourglass))
        else
          ...vm.wishlist.take(3).map((w) => _WishlistRow(item: w, vm: vm, now: now)),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final price = TextEditingController();
    await showAppSheet<void>(
      context,
      title: tr('Tahan dulu 48 jam'),
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          AppTextField(controller: name, hint: tr('Barang yang diinginkan'), autofocus: true),
          AppTextField(controller: price, hint: tr('Harga (Rp)'), keyboardType: TextInputType.number),
          InfoBanner(icon: AppIcons.info, text: tr('Pasanganmu bisa memberi tanggapan "setuju" atau "nanti dulu" selama masa tunggu.')),
          PrimaryButton(
            label: tr('Simpan'),
            height: 52,
            onPressed: () async {
              final p = double.tryParse(price.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
              if (name.text.trim().isEmpty || p <= 0) return;
              await vm.addWishlist(name.text.trim(), p);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  final WishlistItemEntity item;
  final FinanceViewModel vm;
  final DateTime now;

  const _WishlistRow({required this.item, required this.vm, required this.now});

  @override
  Widget build(BuildContext context) {
    final left = item.remaining(now);
    final done = left == Duration.zero;
    final mine = item.addedByUid == vm.uid;
    final hours = left.inHours + (left.inMinutes % 60 > 0 ? 1 : 0);
    final response = item.response == null ? '' : ' ${item.responseByName?.split(' ').first}: “${item.response}”';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: item.holdProgress(now), strokeWidth: 4, color: AppColors.rose, backgroundColor: AppColors.track),
              Text(done ? 'OK' : '${hours}j', style: AppText.body(13, weight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Text('${item.name} · ${formatRupiahShort(item.price)}', style: AppText.body(15, weight: FontWeight.w600)),
              Text(
                done ? tr('Masa tunggu selesai.{0}', [response]) : tr('Tunggu {0} jam lagi.{1}', [hours, response]),
                style: AppText.body(12, color: AppColors.muted, height: 1.35),
              ),
              if (!mine && item.response == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(spacing: 8, children: [
                    GestureDetector(onTap: () => vm.respondWishlist(item, 'setuju'), child: Pill(tr('Setuju'))),
                    GestureDetector(onTap: () => vm.respondWishlist(item, tr('nanti dulu ya')), child: Pill(tr('Nanti dulu'), color: AppColors.rose, background: AppColors.roseSoft)),
                  ]),
                ),
            ]),
          ),
          if (done)
            GestureDetector(onTap: () => vm.removeWishlist(item), child: const Icon(AppIcons.x, size: 18, color: AppColors.faint)),
        ],
      ),
    );
  }
}
