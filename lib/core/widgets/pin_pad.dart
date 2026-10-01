import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/app_text.dart';
import 'ui_kit.dart';
import '../theme/app_icons.dart';
import '../l10n/app_locale.dart';

/// Papan PIN 6 angka bergaya kaca. [onCompleted] dipanggil saat 6 angka terisi.
class PinPad extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<bool> Function(String pin) onCompleted;
  final VoidCallback? onBiometric;

  const PinPad({super.key, required this.title, required this.subtitle, required this.onCompleted, this.onBiometric});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _error = false;

  Future<void> _press(String key) async {
    if (key == 'del') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += key;
      _error = false;
    });
    if (_pin.length == 6) {
      final ok = await widget.onCompleted(_pin);
      if (!mounted) return;
      if (!ok) {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['bio', '0', 'del'],
    ];
    return Column(
      spacing: 10,
      children: [
        GlassCard(radius: 24, padding: const EdgeInsets.all(20), child: const Icon(AppIcons.lockKeyhole, size: 30, color: AppColors.jade)),
        Text(widget.title, style: AppText.display(22)),
        Text(
          _error ? tr('PIN salah, coba lagi.') : widget.subtitle,
          textAlign: TextAlign.center,
          style: AppText.body(13, color: _error ? AppColors.rose : AppColors.muted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: List.generate(
              6,
              (i) => Container(width: 14, height: 14, decoration: BoxDecoration(color: i < _pin.length ? AppColors.ink : const Color(0x1F15201D), shape: BoxShape.circle)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            spacing: 12,
            children: rows
                .map((r) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: r.map((k) {
                        if (k == 'bio') {
                          return SizedBox(
                            width: 72,
                            height: 72,
                            child: widget.onBiometric == null
                                ? null
                                : IconButton(onPressed: widget.onBiometric, icon: const Icon(AppIcons.scanFace, size: 26, color: AppColors.jade)),
                          );
                        }
                        if (k == 'del') {
                          return SizedBox(width: 72, height: 72, child: IconButton(onPressed: () => _press('del'), icon: const Icon(AppIcons.delete, size: 24, color: AppColors.ink)));
                        }
                        return GestureDetector(
                          onTap: () => _press(k),
                          child: GlassCard(
                            radius: 36,
                            padding: EdgeInsets.zero,
                            child: SizedBox(width: 72, height: 72, child: Center(child: Text(k, style: AppText.display(28, letterSpacing: 0).copyWith(fontWeight: FontWeight.w500)))),
                          ),
                        );
                      }).toList(),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
