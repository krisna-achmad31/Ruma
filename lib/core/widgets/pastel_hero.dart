import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'ui_kit.dart';

/// Pasangan warna kartu hero V2: gradasi pastel, warna label, dan aksen.
class PastelTone {
  final List<Color> colors;
  final Color label;
  final Color accent;
  final bool dark;

  const PastelTone(this.colors, this.label, this.accent, {this.dark = false});

  static const mint = PastelTone([Color(0xFFCFE8DC), Color(0xFFE9F4EE)], Color(0xFF1F5446), AppColors.jade);
  static const sky = PastelTone([Color(0xFFC7DDF5), Color(0xFFE3EEFA)], Color(0xFF2D5C88), AppColors.sky);
  static const butter = PastelTone([Color(0xFFF8E2A6), Color(0xFFFCE6D2)], Color(0xFF7A5A0E), AppColors.butter);
  static const peach = PastelTone([Color(0xFFF9D9C2), Color(0xFFFCE9DC)], Color(0xFF8A4B1E), AppColors.amber);
  static const rose = PastelTone([Color(0xFFF7C9D5), Color(0xFFFADFE6)], Color(0xFF8E3A50), AppColors.rose);
  static const lilac = PastelTone([Color(0xFFDCD3F3), Color(0xFFEEE9FA)], Color(0xFF4E3E8C), AppColors.lilac);
  static const jade = PastelTone(AppColors.jadeGradient, Color(0xCCFFFFFF), Colors.white, dark: true);
  static const night = PastelTone([Color(0xFF15201D), Color(0xFF2A2440)], Color(0xFFC9BEF0), Colors.white, dark: true);

  /// Hero pastel dari pasangan warna (aksen, latar lembut) milik amplop atau dompet.
  factory PastelTone.of((Color, Color) tone) =>
      PastelTone([Color.lerp(tone.$2, Colors.white, 0.35)!, tone.$2], Color.lerp(tone.$1, AppColors.ink, 0.25)!, tone.$1);

  Color get text => dark ? Colors.white : AppColors.ink;
  Color get subtext => dark ? const Color(0xB3FFFFFF) : AppColors.muted;
}

/// Objek 3D dari assets/icons3d, bisa diputar sedikit supaya terasa hidup.
class Object3D extends StatelessWidget {
  final String name;
  final double size;
  final double rotation;

  const Object3D(this.name, {super.key, this.size = 40, this.rotation = 0});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(AppIcons.object3d(name), width: size, height: size, filterQuality: FilterQuality.medium);
    if (rotation == 0) return image;
    return Transform.rotate(angle: rotation * math.pi / 180, child: image);
  }
}

/// Kartu hero V2: gradasi pastel dengan objek 3D besar yang keluar dari pojok kanan atas.
/// [head] diberi ruang di kanan supaya tidak tertutup objek, [body] memakai lebar penuh.
class PastelHero extends StatelessWidget {
  final PastelTone tone;
  final String object;
  final double objectSize;
  final double objectRotation;
  final String? label;
  final bool plus;
  final Widget head;
  final Widget? body;
  final VoidCallback? onTap;
  final double? reserve;

  const PastelHero({
    super.key,
    required this.tone,
    required this.object,
    required this.head,
    this.body,
    this.label,
    this.plus = false,
    this.objectSize = 116,
    this.objectRotation = -12,
    this.onTap,
    this.reserve,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone.colors),
        border: tone.dark ? null : Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: [BoxShadow(color: tone.accent.withValues(alpha: tone.dark ? 0.25 : 0.2), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(right: -6, top: -6, child: IgnorePointer(child: Object3D(object, size: objectSize, rotation: objectRotation))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: reserve ?? objectSize * 0.78),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        if (label != null)
                          Row(spacing: 6, children: [
                            Flexible(child: Text(label!, style: AppText.body(12, weight: FontWeight.w700, color: tone.label))),
                            if (plus) const PlusBadge(onDark: true),
                          ]),
                        head,
                      ],
                    ),
                  ),
                  ?body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// Angka utama hero yang mengecil sendiri kalau ruangnya sempit.
class HeroNumber extends StatelessWidget {
  final String text;
  final double size;
  final Color color;

  const HeroNumber(this.text, {super.key, this.size = 34, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: AppText.display(size, color: color, letterSpacing: -size * 0.035, height: 1)),
    );
  }
}

/// Bar progres untuk di atas latar pastel atau gelap.
class HeroBar extends StatelessWidget {
  final double value;
  final PastelTone tone;
  final Color? color;

  const HeroBar({super.key, required this.value, required this.tone, this.color});

  @override
  Widget build(BuildContext context) {
    return ProgressBar(
      value: value,
      height: 8,
      color: color ?? (tone.dark ? Colors.white : tone.accent),
      track: tone.dark ? const Color(0x2EFFFFFF) : const Color(0x80FFFFFF),
    );
  }
}

/// Tombol kecil berbentuk kapsul untuk di dalam hero.
class HeroButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool light;

  const HeroButton({super.key, required this.label, this.icon, this.onTap, this.light = false});

  @override
  Widget build(BuildContext context) {
    final fg = light ? AppColors.ink : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: light ? Colors.white : AppColors.ink, borderRadius: BorderRadius.circular(22)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (icon != null) Icon(icon, size: 16, color: fg),
            Text(label, style: AppText.body(14, weight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
