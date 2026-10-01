import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_icons.dart';
import '../l10n/app_locale.dart';

enum AppTab { today, urusan, uang, kita, rumah }

/// Tab bar kapsul kaca yang melayang di bawah layar.
class AppTabBar extends StatelessWidget {
  final AppTab current;

  const AppTabBar({super.key, required this.current});

  static const _items = [
    (AppTab.today, 'Hari ini', AppIcons.sun, '/'),
    (AppTab.urusan, 'Urusan', AppIcons.listChecks, '/urusan'),
    (AppTab.uang, 'Uang', AppIcons.wallet, '/finance'),
    (AppTab.kita, 'Kita', AppIcons.heart, '/together'),
    (AppTab.rumah, 'Rumah', AppIcons.house, '/more'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = current == AppTab.kita ? AppColors.rose : AppColors.jade;
    final accentSoft = current == AppTab.kita ? AppColors.roseSoft : AppColors.jadeSoft;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            boxShadow: const [BoxShadow(color: Color(0x1F15201D), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(31),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.glassStrong,
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(color: AppColors.glassEdge),
                ),
                child: Row(
                  children: _items.map((item) {
                    final selected = item.$1 == current;
                    final color = selected ? accent : AppColors.faint;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: selected ? null : () => context.go(item.$4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? accentSoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.$3, size: 24, color: color, fill: selected ? 1 : 0),
                              const SizedBox(height: 2),
                              Text(tr(item.$2), style: AppText.body(10, weight: FontWeight.w600, color: color)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
