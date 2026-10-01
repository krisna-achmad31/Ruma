import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import 'ui_kit.dart';
import '../theme/app_icons.dart';
import '../l10n/app_locale.dart';

/// Bottom sheet kaca dengan handle dan judul.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6615201D),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: const Color(0xF2FFFFFF),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  Center(
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0x2615201D), borderRadius: BorderRadius.circular(3))),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(title, style: AppText.display(20, letterSpacing: -0.3))),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0x0D15201D), shape: BoxShape.circle),
                          child: const Icon(AppIcons.x, size: 16, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                  Flexible(child: SingleChildScrollView(child: builder(sheetContext))),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dialog konfirmasi kaca. Mengembalikan true kalau aksi utama dipilih.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = AppIcons.circleAlert,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x6615201D),
    builder: (dialogContext) => Dialog(
      backgroundColor: const Color(0xF2FFFFFF),
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            IconBox(
              icon: icon,
              size: 56,
              color: destructive ? AppColors.rose : AppColors.jade,
              background: destructive ? AppColors.roseSoft : AppColors.jadeSoft,
            ),
            Text(title, style: AppText.display(21), textAlign: TextAlign.center),
            Text(message, style: AppText.body(14, color: AppColors.muted, height: 1.4), textAlign: TextAlign.center),
            Column(
              spacing: 8,
              children: [
                PrimaryButton(
                  label: confirmLabel,
                  height: 52,
                  color: destructive ? AppColors.rose : AppColors.ink,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(false),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0x0D15201D), borderRadius: BorderRadius.circular(26)),
                    child: Text(tr('Batal'), style: AppText.body(15, weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Sheet isian nominal dengan pilihan cepat.
Future<double?> showAmountSheet(
  BuildContext context, {
  required String title,
  required double initial,
  String? caption,
  String? hint,
  String? confirmLabel,
}) {
  final controller = TextEditingController(text: initial > 0 ? initial.round().toString() : '');
  final presets = initial > 0 ? [initial * 0.875, initial, initial * 1.125] : <double>[];
  return showAppSheet<double>(
    context,
    title: title,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final value = double.tryParse(controller.text) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Column(
              spacing: 4,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.display(38, letterSpacing: -1.2),
                  decoration: const InputDecoration(border: InputBorder.none, prefixText: 'Rp', isCollapsed: true),
                  onChanged: (_) => setState(() {}),
                ),
                if (caption != null) Text(caption, style: AppText.body(13, color: AppColors.muted)),
              ],
            ),
            if (presets.isNotEmpty)
              Row(
                spacing: 8,
                children: presets.map((p) {
                  final sel = (p - value).abs() < 1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => controller.text = p.round().toString()),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: sel ? AppColors.jade : const Color(0x0D15201D), borderRadius: BorderRadius.circular(20)),
                        child: Text(formatRupiahShort(p), style: AppText.body(13, weight: FontWeight.w700, color: sel ? Colors.white : AppColors.ink)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (hint != null) InfoBanner(icon: AppIcons.info, text: hint),
            PrimaryButton(
              label: confirmLabel ?? tr('Simpan'),
              height: 52,
              onPressed: value > 0 ? () => Navigator.of(sheetContext).pop(value) : null,
            ),
          ],
        );
      },
    ),
  );
}

/// Sheet isian teks satu baris.
Future<String?> showTextSheet(BuildContext context, {required String title, String initial = '', String hint = '', String? confirmLabel, TextInputType? keyboardType}) {
  final controller = TextEditingController(text: initial);
  return showAppSheet<String>(
    context,
    title: title,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        AppTextField(controller: controller, hint: hint, autofocus: true, keyboardType: keyboardType),
        PrimaryButton(
          label: confirmLabel ?? tr('Simpan'),
          height: 52,
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.of(sheetContext).pop(text);
          },
        ),
      ],
    ),
  );
}

/// Sheet pilihan dari daftar.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  String Function(T)? sublabel,
  IconData Function(T)? icon,
  T? selected,
}) {
  return showAppSheet<T>(
    context,
    title: title,
    builder: (sheetContext) => Column(
      children: items.map((item) {
        final isSel = item == selected;
        return GestureDetector(
          onTap: () => Navigator.of(sheetContext).pop(item),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isSel ? AppColors.jadeSoft : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Row(
              spacing: 12,
              children: [
                if (icon != null) IconBox(icon: icon(item), background: isSel ? const Color(0xB3FFFFFF) : AppColors.jadeSoft),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Text(label(item), style: AppText.body(15, weight: FontWeight.w600)),
                      if (sublabel != null) Text(sublabel(item), style: AppText.body(12, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (isSel) const Icon(AppIcons.circleCheck, size: 20, color: AppColors.jade),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.autofocus = false,
    this.maxLines = 1,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: AppText.body(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(15, color: AppColors.faint),
        filled: true,
        fillColor: AppColors.glassStrong,
        prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.faint) : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.glassEdge)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.jade, width: 1.5)),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [Text(label, style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)), child],
    );
  }
}
