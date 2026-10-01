import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Paywall Plus: satu langganan dipakai berdua.
/// Pembayaran belum tersambung ke Google Play Billing, jadi tombol utama baru memberi tahu.
class PaywallScreen extends StatefulWidget {
  final bool fromOnboarding;

  const PaywallScreen({super.key, this.fromOnboarding = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  static const _features = [
    (AppIcons.gem, AppColors.rose, 'Siap nikah & menyambut bayi', 'Pendamping di fase hidup paling sibuk'),
    (AppIcons.calendarClock, AppColors.amber, 'Cicilan & paylater', 'Semua jatuh tempo di satu tempat'),
    (AppIcons.messageCircleHeart, AppColors.rose, 'Money date mingguan', 'Obrolan uang 10 menit yang terarah'),
    (AppIcons.clipboardCheck, AppColors.jade, 'Rapor rumah tangga', 'Lihat perkembangan kalian tiap bulan'),
    (AppIcons.shieldCheck, AppColors.jade, 'Brankas rumah', 'Nomor penting, polis, dan garansi'),
  ];

  void _close() => widget.fromOnboarding ? context.go('/') : (context.canPop() ? context.pop() : context.go('/'));

  Widget _plan({required bool yearly, required String name, required String detail, required String price, String? badge}) {
    final sel = _yearly == yearly;
    return GlassCard(
      strong: sel,
      radius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: sel ? AppColors.jade : null,
      borderWidth: sel ? 2 : 1,
      onTap: () => setState(() => _yearly = yearly),
      child: Row(spacing: 14, children: [
        CheckCircle(checked: sel, size: 22),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
            Row(spacing: 8, children: [
              Text(name, style: AppText.body(16, weight: FontWeight.w700)),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.jade, borderRadius: BorderRadius.circular(7)),
                  child: Text(badge, style: AppText.body(10, weight: FontWeight.w700, color: Colors.white)),
                ),
            ]),
            Text(detail, style: AppText.body(12, color: AppColors.muted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: AppText.display(18)),
          Text(tr('/bln berdua'), style: AppText.body(11, color: AppColors.muted)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      gap: 22,
      bottom: Column(mainAxisSize: MainAxisSize.min, spacing: 10, children: [
        PrimaryButton(
          label: _yearly ? tr('Coba gratis 14 hari') : tr('Langganan bulanan'),
          onPressed: () => showSnack(context, tr('Pembayaran lewat Google Play belum aktif di versi ini.')),
        ),
        Text(tr('Batalkan kapan saja. Kami ingatkan 2 hari sebelum trial berakhir.'), textAlign: TextAlign.center, style: AppText.body(12, color: AppColors.muted, height: 1.4)),
      ]),
      children: [
        Align(alignment: Alignment.centerLeft, child: GlassCircleButton(icon: AppIcons.x, size: 36, onTap: _close)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
          const PlusBadge(),
          Text(tr('Satu langganan, dipakai berdua.'), style: AppText.display(32, letterSpacing: -0.9, height: 1.1)),
          Text(tr('Kalau kamu langganan, pasanganmu otomatis ikut dapat Plus.'), style: AppText.body(15, color: AppColors.muted)),
        ]),
        Column(
          spacing: 14,
          children: _features
              .map((f) => Row(spacing: 14, children: [
                    IconBox(icon: f.$1, color: f.$2, background: AppColors.glassStrong, size: 44),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                        Text(tr(f.$3), style: AppText.body(15, weight: FontWeight.w700)),
                        Text(tr(f.$4), style: AppText.body(13, color: AppColors.muted)),
                      ]),
                    ),
                  ]))
              .toList(),
        ),
        Column(spacing: 10, children: [
          _plan(yearly: true, name: tr('Tahunan'), detail: tr('Gratis 14 hari, lalu Rp199.000/tahun'), price: tr('Rp16rb'), badge: tr('Hemat 43%')),
          _plan(yearly: false, name: tr('Bulanan'), detail: tr('Tanpa trial'), price: tr('Rp29rb')),
        ]),
      ],
    );
  }
}
