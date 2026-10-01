import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pastel_hero.dart';
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
    (AppIcons.gem, AppColors.roseSoft, 'Fase hidup', 'Siap nikah, menyambut bayi, Lebaran & THR'),
    (AppIcons.creditCard, AppColors.amberSoft, 'Cicilan & paylater', 'Semua jatuh tempo di satu tempat'),
    (AppIcons.messagesSquare, AppColors.lilacSoft, 'Money date mingguan', 'Obrolan uang 10 menit yang terarah'),
    (AppIcons.chartColumn, AppColors.jadeSoft, 'Rapor rumah tangga', 'Lihat perkembangan kalian tiap bulan'),
    (AppIcons.lock, AppColors.skySoft, 'Brankas rumah', 'Nomor penting, polis, dan garansi'),
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
        Text(tr('Batalkan kapan saja dari Google Play.'), textAlign: TextAlign.center, style: AppText.body(12, color: AppColors.muted, height: 1.4)),
      ]),
      children: [
        Row(children: [
          GlassCircleButton(icon: AppIcons.x, size: 44, onTap: _close),
          const Spacer(),
          const Object3D('heart_hands', size: 52),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
          const PlusBadge(),
          Text(tr('Satu langganan, dipakai berdua.'), style: AppText.display(32, letterSpacing: -0.9, height: 1.1)),
          Text(tr('Kalau kamu langganan, pasanganmu otomatis ikut dapat Plus.'), style: AppText.body(15, color: AppColors.muted)),
        ]),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
          spacing: 12,
          children: _features
              .map((f) => Row(spacing: 12, children: [
                    IconBox(icon: f.$1, background: f.$2, size: 40),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                        Text(tr(f.$3), style: AppText.body(15, weight: FontWeight.w700)),
                        Text(tr(f.$4), style: AppText.body(13, color: AppColors.muted)),
                      ]),
                    ),
                  ]))
              .toList(),
          ),
        ),
        Column(spacing: 10, children: [
          _plan(yearly: true, name: tr('Tahunan'), detail: tr('Gratis 14 hari, lalu Rp199.000/tahun'), price: tr('Rp16rb'), badge: tr('Hemat 43%')),
          _plan(yearly: false, name: tr('Bulanan'), detail: tr('Tanpa trial'), price: tr('Rp29rb')),
        ]),
        if (_yearly) const _TrialTimeline(),
      ],
    );
  }
}

/// Alur masa coba supaya pengguna tahu persis kapan ditagih.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (tr('Hari ini'), tr('Semua fitur Plus terbuka untuk berdua'), AppColors.jade),
      (tr('Hari ke-12'), tr('Kami ingatkan lewat notifikasi'), AppColors.amber),
      (tr('Hari ke-14'), tr('Rp199.000 ditagih, kecuali dibatalkan'), AppColors.muted),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
      Text(tr('Cara kerja masa coba'), style: AppText.body(15, weight: FontWeight.w700)),
      Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
              Row(spacing: 4, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: steps[i].$3, shape: BoxShape.circle)),
                Expanded(child: Container(height: 2, color: i < steps.length - 1 ? AppColors.hairline : Colors.transparent)),
              ]),
              Text(steps[i].$1, style: AppText.body(12, weight: FontWeight.w700, color: steps[i].$3)),
              Text(steps[i].$2, style: AppText.body(11, color: AppColors.muted, height: 1.35)),
            ]),
          ),
      ]),
    ]);
  }
}
