import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/l10n/app_locale.dart';

/// Onboarding 3 halaman: tagline, urusan tanpa hitung-hitungan, dan waktu berdua.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _copy = [
    (AppBrand.taglineId, 'Urusan rumah, uang, dan waktu berdua dalam satu tempat.'),
    ('Kerja yang nggak kelihatan, jadi kelihatan.', 'Siapa yang ingat, siapa yang kerjakan. Tanpa hitung-hitungan, cuma saling bantu.'),
    ('Dua menit sehari untuk berdua.', 'Check-in harian, obrolan malam, dan uang rumah yang digabung. Satu langganan untuk berdua.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final last = _page == 2;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Row(children: [
                  Row(spacing: 8, children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F5446), Color(0xFF3D8270)])),
                      child: const Object3D('house', size: 24),
                    ),
                    Text(AppBrand.name, style: AppText.display(18, letterSpacing: -0.4)),
                  ]),
                  const Spacer(),
                  const _LanguageToggle(),
                  if (!last) const SizedBox(width: 16),
                  if (!last)
                    GestureDetector(
                      onTap: () => _controller.animateToPage(2, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
                      child: Text(tr('Lewati'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.muted)),
                    ),
                ]),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (p) => setState(() => _page = p),
                    // Kecilkan ilustrasi kalau layar pendek, supaya tidak terpotong.
                    children: [
                      for (final page in const [_PageOne(), _PageTwo(), _PageThree()])
                        LayoutBuilder(
                          builder: (context, box) => Center(
                            child: FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: box.maxWidth, child: page)),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(_page),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(tr(_copy[_page].$1), style: AppText.display(32, letterSpacing: -1, height: 1.08)),
                      Text(tr(_copy[_page].$2), style: AppText.body(15, color: AppColors.muted, height: 1.45)),
                    ],
                  ),
                ),
                Row(
                  spacing: 6,
                  children: List.generate(3, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: i == _page ? AppColors.jade : const Color(0x2615201D), borderRadius: BorderRadius.circular(4)),
                    );
                  }),
                ),
                if (!last)
                  PrimaryButton(label: tr('Lanjut'), onPressed: _next)
                else ...[
                  PrimaryButton(label: tr('Mulai berdua'), onPressed: () => context.push('/register')),
                  PrimaryButton(label: tr('Aku punya kode undangan'), secondary: true, onPressed: () => context.push('/login?next=join')),
                ],
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Center(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: tr('Sudah punya akun? '), style: AppText.body(14, color: AppColors.muted)),
                      TextSpan(text: tr('Masuk'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.jade)),
                    ])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _tilt(double degrees, Widget child) => Transform.rotate(angle: -degrees * math.pi / 180, child: child);

class _PageOne extends StatelessWidget {
  const _PageOne();

  @override
  Widget build(BuildContext context) {
    final cards = [
      (AppIcons.heart, AppColors.roseSoft, tr('Dinda lagi capek'), tr('energi 2 dari 5, butuh malam tenang'), -3.0, 0.0, tr('Kita'), AppColors.rose),
      (AppIcons.wallet, AppColors.jadeSoft, tr('Rp182.000'), tr('aman dipakai hari ini'), 2.0, 40.0, tr('Uang'), AppColors.jade),
      (AppIcons.heartHandshake, AppColors.amberSoft, tr('Makasih udah bayar listrik'), tr('dari Dinda, barusan'), -2.0, 10.0, tr('Urusan'), AppColors.amber),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 14,
      children: cards
          .map((c) => Padding(
                padding: EdgeInsets.only(left: c.$6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _tilt(
                    c.$5,
                    SizedBox(
                      width: 270,
                      child: GlassCard(
                        strong: true,
                        radius: 20,
                        padding: const EdgeInsets.all(14),
                        child: Row(spacing: 12, children: [
                          IconBox(icon: c.$1, background: c.$2, size: 42),
                          Expanded(
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                              Text(c.$7, style: AppText.body(10, weight: FontWeight.w700, color: c.$8)),
                              Text(c.$3, style: AppText.body(15, weight: FontWeight.w700, color: c.$1 == AppIcons.wallet ? AppColors.jade : AppColors.ink)),
                              Text(c.$4, style: AppText.body(12, color: AppColors.muted)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _PageTwo extends StatelessWidget {
  const _PageTwo();

  Widget _role(String t, Color c, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: AppText.body(11, weight: FontWeight.w600, color: c)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _tilt(
          2,
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: AppColors.warmGradient),
              border: Border.all(color: AppColors.glassEdge),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
              Row(spacing: 10, children: [
                const IconBox(icon: AppIcons.brain, background: Color(0xB3FFFFFF), size: 34),
                Text(tr('Yang dipikirin diam-diam'), style: AppText.body(15, weight: FontWeight.w700)),
              ]),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in [tr('Jadwal imunisasi Kia'), tr('Stok beras tinggal 2 kg'), tr('Ulang tahun Ibu')])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(14)),
                    child: Text(c, style: AppText.body(13, weight: FontWeight.w500)),
                  ),
              ]),
            ]),
          ),
        ),
        _tilt(
          -1.5,
          GlassCard(
            strong: true,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
              Row(spacing: 12, children: [const CheckCircle(checked: false), Text(tr('Bayar listrik PLN'), style: AppText.body(15, weight: FontWeight.w600))]),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Row(spacing: 6, children: [_role(tr('Kamu ingat'), AppColors.muted, AppColors.fieldFill), _role(tr('Dinda kerjakan'), AppColors.muted, AppColors.fieldFill)]),
              ),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: Text(tr('Bilang makasih ke Dinda'), style: AppText.body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _PageThree extends StatelessWidget {
  const _PageThree();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _tilt(
          1.5,
          GlassCard(
            strong: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
              Text(tr('Gimana kamu hari ini?'), style: AppText.display(19)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  return Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 3 ? Colors.white : const Color(0x0A15201D),
                      shape: BoxShape.circle,
                      border: i == 3 ? Border.all(color: AppColors.rose, width: 2) : null,
                    ),
                    child: Image.asset(AppIcons.moodAsset(i), width: i == 3 ? 34 : 30, height: i == 3 ? 34 : 30),
                  );
                }),
              ),
            ]),
          ),
        ),
        Row(
          spacing: 10,
          children: [
            (AppIcons.flame, AppColors.amberSoft, tr('23 hari'), tr('check-in berdua')),
            (AppIcons.wallet, AppColors.jadeSoft, tr('Uang rumah'), tr('digabung, bukan dipisah')),
          ]
              .map((c) => Expanded(
                    child: GlassCard(
                      strong: true,
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                        IconBox(icon: c.$1, background: c.$2, size: 38),
                        Text(c.$3, style: AppText.body(15, weight: FontWeight.w700)),
                        Text(c.$4, style: AppText.body(12, color: AppColors.muted)),
                      ]),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Pilihan bahasa ID atau EN, supaya pengguna bisa ganti sebelum masuk.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final current = AppLocale.instance.code;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.glassEdge)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final code in AppLocale.supported)
          GestureDetector(
            onTap: () => AppLocale.instance.setCode(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: code == current ? AppColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(11)),
              child: Text(code.toUpperCase(), style: AppText.body(12, weight: FontWeight.w700, color: code == current ? Colors.white : AppColors.muted)),
            ),
          ),
      ]),
    );
  }
}
