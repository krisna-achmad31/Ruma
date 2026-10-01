import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../theme/app_icons.dart';
import '../l10n/app_locale.dart';

/// Kartu kaca: putih transparan, tepi terang, bayangan lembut.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool strong;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.strong = false,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (strong ? AppColors.glassStrong : AppColors.glass),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.glassEdge, width: borderWidth),
        boxShadow: const [BoxShadow(color: Color(0x0F15201D), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// Tombol bulat kaca dengan blur, dipakai untuk kembali dan aksi di header.
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool badge;

  const GlassCircleButton({super.key, required this.icon, this.onTap, this.size = 40, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassEdge),
                  ),
                  child: Icon(icon, size: size * 0.46, color: AppColors.ink),
                ),
              ),
            ),
            if (badge)
              Positioned(
                right: size * 0.2,
                top: size * 0.2,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Header sub-halaman: tombol kembali, judul di tengah, aksi opsional di kanan.
class AppNavBar extends StatelessWidget {
  final String title;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final IconData leadingIcon;
  final VoidCallback? onLeading;

  const AppNavBar({
    super.key,
    required this.title,
    this.actionIcon,
    this.onAction,
    this.leadingIcon = AppIcons.chevronLeft,
    this.onLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassCircleButton(
          icon: leadingIcon,
          onTap: onLeading ?? () => context.canPop() ? context.pop() : context.go('/'),
        ),
        Expanded(child: Text(title, textAlign: TextAlign.center, style: AppText.navTitle, overflow: TextOverflow.ellipsis)),
        if (actionIcon != null) GlassCircleButton(icon: actionIcon!, onTap: onAction) else const SizedBox(width: 40),
      ],
    );
  }
}

class LargeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool subtitleAbove;

  const LargeTitle({super.key, required this.title, this.subtitle, this.trailing, this.subtitleAbove = false});

  @override
  Widget build(BuildContext context) {
    final sub = subtitle == null
        ? null
        : Text(subtitle!, style: AppText.body(14, weight: FontWeight.w500, color: AppColors.muted));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              if (sub != null && subtitleAbove) sub,
              Text(title, style: AppText.largeTitle),
              if (sub != null && !subtitleAbove) sub,
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color actionColor;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.actionColor = AppColors.jade, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AppText.sectionTitle)),
        ?trailing,
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppText.body(14, weight: FontWeight.w600, color: actionColor)),
          ),
      ],
    );
  }
}

class GroupLabel extends StatelessWidget {
  final String text;

  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text, style: AppText.body(12, weight: FontWeight.w600, color: AppColors.faint));
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double? radius;

  /// True untuk memaksa ikon Material datar walau ada versi 3D-nya.
  final bool flat;

  const IconBox({
    super.key,
    required this.icon,
    this.color = AppColors.jade,
    this.background = AppColors.jadeSoft,
    this.size = 38,
    this.radius,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final asset = flat ? null : AppIcons.assetFor(icon);
    final r = BorderRadius.circular(radius ?? size * 0.32);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: r,
        color: background,
        // Kilap lembut di bagian atas supaya kotak pastel terasa timbul.
        gradient: asset == null ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(background, Colors.white, 0.55)!, background]),
        border: asset == null ? null : Border.all(color: const Color(0x99FFFFFF)),
      ),
      child: asset == null
          ? Icon(icon, size: size * 0.5, color: color, fill: 1)
          : Image.asset(asset, width: size * 0.66, height: size * 0.66, filterQuality: FilterQuality.medium),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  const Pill(this.text, {super.key, this.color = AppColors.jade, this.background = AppColors.jadeSoft, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) Icon(icon, size: 12, color: color),
          Text(text, style: AppText.body(11, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class PlusBadge extends StatelessWidget {
  final bool onDark;

  const PlusBadge({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: onDark ? const Color(0xCCFFFFFF) : AppColors.ink,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(tr('Plus'), style: AppText.body(10, weight: FontWeight.w700, color: onDark ? AppColors.ink : Colors.white)),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color track;

  const ProgressBar({super.key, required this.value, this.color = AppColors.jade, this.height = 6, this.track = AppColors.track});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: v == 0 ? 0.015 : v,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color selectedTextColor;
  final double height;

  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.selectedTextColor = AppColors.ink,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      radius: height / 2,
      child: SizedBox(
        height: height - 10,
        child: Row(
          children: List.generate(labels.length, (i) {
            final isSel = i == selected;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(height / 2 - 4),
                    boxShadow: isSel ? const [BoxShadow(color: Color(0x1415201D), blurRadius: 8, offset: Offset(0, 2))] : null,
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.body(13, weight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? selectedTextColor : AppColors.muted),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Baris daftar standar: ikon, judul, keterangan, dan elemen kanan.
class ListRow extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Color titleColor;
  final Widget? trailing;
  final String? trailingText;
  final Color trailingColor;
  final bool chevron;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? below;

  const ListRow({
    super.key,
    this.icon,
    this.iconColor = AppColors.jade,
    this.iconBackground = AppColors.jadeSoft,
    required this.title,
    this.subtitle,
    this.titleColor = AppColors.ink,
    this.trailing,
    this.trailingText,
    this.trailingColor = AppColors.ink,
    this.chevron = false,
    this.onTap,
    this.leading,
    this.below,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            ?leading,
            if (leading == null && icon != null) IconBox(icon: icon!, color: iconColor, background: iconBackground),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: AppText.body(15, weight: FontWeight.w600, color: titleColor)),
                  if (subtitle != null) Text(subtitle!, style: AppText.body(12, color: AppColors.muted)),
                  ?below,
                ],
              ),
            ),
            if (trailingText != null) Text(trailingText!, style: AppText.body(14, weight: FontWeight.w700, color: trailingColor)),
            ?trailing,
            if (chevron) const Icon(AppIcons.chevronRight, size: 16, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// Kartu kaca berisi baris-baris dengan garis pemisah tipis.
class ListCard extends StatelessWidget {
  final List<Widget> children;

  const ListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ],
        ],
      ),
    );
  }
}

class LabeledGroup extends StatelessWidget {
  final String label;
  final List<Widget> rows;

  const LabeledGroup({super.key, required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [GroupLabel(label), ListCard(children: rows)],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final Color? color;
  final bool loading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.secondary = false,
    this.color,
    this.loading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final fg = secondary ? AppColors.ink : Colors.white;
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: secondary ? AppColors.glassStrong : (color ?? AppColors.ink),
            borderRadius: BorderRadius.circular(height / 2),
            border: secondary ? Border.all(color: AppColors.glassEdge) : null,
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    if (icon != null) Icon(icon, size: 17, color: fg),
                    Text(label, style: AppText.body(16, weight: FontWeight.w700, color: fg)),
                  ],
                ),
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color background;
  final Widget? trailing;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.jade,
    this.background = AppColors.jadeSoft,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, size: 18, color: color),
          Expanded(child: Text(text, style: AppText.body(13, height: 1.35))),
          ?trailing,
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final bool ring;

  const Avatar({super.key, required this.name, this.color = AppColors.jade, this.size = 32, this.ring = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Text(initialOf(name), style: AppText.body(size * 0.4, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}

/// Kartu gradasi untuk angka utama di tiap modul.
class HeroCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const HeroCard({super.key, required this.colors, required this.child, this.padding = const EdgeInsets.all(22), this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: child,
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyNote(this.text, {super.key, this.icon = AppIcons.inbox});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, size: 18, color: AppColors.faint),
          Expanded(child: Text(text, style: AppText.body(13, color: AppColors.muted))),
        ],
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final (Color, Color) tone;
  final VoidCallback onTap;

  const ShortcutTile({super.key, required this.label, required this.icon, required this.onTap, this.tone = (AppColors.jade, AppColors.jadeSoft)});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          spacing: 8,
          children: [
            IconBox(icon: icon, size: 36, color: tone.$1, background: tone.$2),
            Text(label, style: AppText.body(11, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class CheckCircle extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  final double size;

  const CheckCircle({super.key, required this.checked, this.onTap, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? AppColors.jade : Colors.transparent,
          shape: BoxShape.circle,
          border: checked ? null : Border.all(color: AppColors.faint, width: 1.5),
        ),
        child: checked ? Icon(AppIcons.check, size: size * 0.55, color: Colors.white) : null,
      ),
    );
  }
}

class GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(color: value ? AppColors.jade : const Color(0x1F15201D), borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x3315201D), blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}

/// Menjalankan penyimpanan dan memberi tahu pengguna kalau gagal (misalnya belum login atau aturan Firestore menolak).
Future<bool> saveOrWarn(BuildContext context, Future<void> save) async {
  try {
    await save;
    return true;
  } catch (e) {
    if (context.mounted) {
      final denied = e.toString().contains('permission-denied');
      showSnack(context, denied ? tr('Gagal menyimpan: akses Firestore ditolak. Pastikan sudah masuk dengan akun.') : tr('Gagal menyimpan, coba lagi.'));
    }
    return false;
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
