import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/notification_entity.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<NotificationsViewModel>(
      create: (user) => NotificationsViewModel(homeRepository: buildHomeRepository(), familyId: user.familyId, uid: user.uid),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  (Color, Color) _tone(NotificationEntity n) {
    switch (n.icon) {
      case 'thanks':
      case 'heart':
      case 'calendar':
        return (AppColors.rose, AppColors.roseSoft);
      case 'payments':
      case 'card':
      case 'hiburan':
        return (AppColors.amber, AppColors.amberSoft);
      default:
        return (AppColors.jade, AppColors.jadeSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();
    final groups = vm.grouped;
    return AppScaffold(
      tab: AppTab.today,
      children: [
        AppNavBar(
          title: tr('Notifikasi'),
          actionIcon: AppIcons.checkCheck,
          onAction: () async {
            await vm.markAllRead();
            if (context.mounted) showSnack(context, tr('Semua notifikasi ditandai sudah dibaca.'));
          },
        ),
        SegmentedControl(labels: [tr('Untukmu'), tr('Semua'), tr('Beres')], selected: vm.segment, onChanged: vm.setSegment),
        if (groups.isEmpty)
          GlassCard(child: EmptyNote(tr('Tidak ada notifikasi di sini.'), icon: AppIcons.bellOff))
        else
          ...groups.entries.map((g) => LabeledGroup(
                label: g.key,
                rows: g.value.map((n) {
                  final tone = _tone(n);
                  return ListRow(
                    icon: iconFor(n.icon),
                    iconColor: tone.$1,
                    iconBackground: tone.$2,
                    title: n.title,
                    subtitle: [if (n.subtitle.isNotEmpty) n.subtitle, vm.timeAgo(n)].join(' · '),
                    trailing: n.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle)),
                    below: n.route == '/urusan' && !n.isRead
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                              child: Text(tr('Aku ambil'), style: AppText.body(12, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          )
                        : null,
                    onTap: () {
                      vm.markRead(n);
                      if (n.route != null) context.go(n.route!);
                    },
                  );
                }).toList(),
              )),
      ],
    );
  }
}
