import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Tab Rumah: data keluarga, kelola rumah, fase hidup, dan akun.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final info = vm.familyInfo;
    const colors = [AppColors.jade, AppColors.rose, AppColors.amber];
    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        LargeTitle(title: tr('Rumah')),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Row(spacing: 12, children: [
                if (vm.members.isEmpty) const IconBox(icon: AppIcons.house, size: 40),
                if (vm.members.isNotEmpty)
                  SizedBox(
                  width: 40.0 + (vm.members.length.clamp(1, 3) - 1) * 30,
                  height: 40,
                  child: Stack(
                    children: List.generate(
                      vm.members.length.clamp(0, 3),
                      (i) => Positioned(left: i * 30.0, child: Avatar(name: vm.members[i].name, color: colors[i % 3], size: 40, ring: true)),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                    Text(info.name.isEmpty ? tr('Rumah kita') : info.name, style: AppText.body(16, weight: FontWeight.w700)),
                    Text([if (info.location.isNotEmpty) info.location, tr('{0} anggota', [vm.members.length])].join(' · '), style: AppText.body(12, color: AppColors.muted)),
                  ]),
                ),
              ]),
              GestureDetector(
                onTap: () => context.push('/invite'),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.jadeSoft, borderRadius: BorderRadius.circular(21)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [
                    const Icon(AppIcons.userPlus, size: 16, color: AppColors.jade),
                    Text(tr('Undang anggota'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.jade)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        LabeledGroup(label: tr('Kelola rumah'), rows: [
          ListRow(icon: AppIcons.wrench, iconColor: AppColors.lilac, iconBackground: AppColors.lilacSoft, title: tr('Rumah sehat'), subtitle: tr('Servis kendaraan, rumah, elektronik'), chevron: true, onTap: () => context.push('/more/maintenance')),
          ListRow(icon: AppIcons.landmark, iconColor: AppColors.sky, iconBackground: AppColors.skySoft, title: tr('Dompet'), subtitle: tr('Bank, e-wallet, tunai'), chevron: true, onTap: () => context.push('/finance/wallets')),
          ListRow(icon: AppIcons.shieldCheck, title: tr('Brankas'), subtitle: tr('Nomor penting & dokumen'), chevron: true, onTap: () => context.push('/settings/important-links')),
          ListRow(icon: AppIcons.chartColumn, iconColor: AppColors.butter, iconBackground: AppColors.butterSoft, title: tr('Rekap'), subtitle: tr('Harian sampai tahunan'), chevron: true, onTap: () => context.push('/finance/report')),
          ListRow(
            icon: AppIcons.bookHeart,
            iconColor: AppColors.rose,
            iconBackground: AppColors.roseSoft,
            title: tr('Jurnal keluarga'),
            subtitle: tr('Cerita & makasih sehari-hari'),
            chevron: true,
            onTap: () => context.push('/together/journal'),
          ),
        ]),
        LabeledGroup(label: tr('Fase hidup & musim'), rows: [
          ListRow(
            icon: AppIcons.gem,
            iconColor: AppColors.rose,
            iconBackground: AppColors.roseSoft,
            title: tr('Siap nikah'),
            subtitle: tr('Anggaran nikah, vendor, obrolan pranikah'),
            trailing: const PlusBadge(),
            chevron: true,
            onTap: () => context.push('/life/wedding'),
          ),
          ListRow(
            icon: AppIcons.baby,
            iconColor: AppColors.amber,
            iconBackground: AppColors.amberSoft,
            title: tr('Menyambut bayi'),
            subtitle: tr('Anggaran persalinan & urusan bayi'),
            trailing: const PlusBadge(),
            chevron: true,
            onTap: () => context.push('/life/baby'),
          ),
          ListRow(icon: AppIcons.moonStar, iconColor: AppColors.lilac, iconBackground: AppColors.lilacSoft, title: tr('Lebaran & THR'), subtitle: tr('Alokasi THR, salam tempel, mudik'), chevron: true, onTap: () => context.push('/life/lebaran')),
          ListRow(icon: AppIcons.shoppingCart, iconColor: AppColors.amber, iconBackground: AppColors.amberSoft, title: tr('Belanja'), subtitle: tr('Daftar belanja bersama & harga terakhir'), chevron: true, onTap: () => context.push('/urusan/shopping')),
          ListRow(icon: AppIcons.layoutGrid, iconColor: AppColors.sky, iconBackground: AppColors.skySoft, title: tr('Widget layar utama'), subtitle: tr('Sisa uang aman, mood, urusan'), chevron: true, onTap: () => context.push('/more/widget')),
        ]),
        LabeledGroup(label: tr('Akun'), rows: [
          ListRow(icon: AppIcons.user, iconColor: AppColors.sky, iconBackground: AppColors.skySoft, title: tr('Profil'), chevron: true, onTap: () => context.push('/settings/profile')),
          ListRow(icon: AppIcons.settings, title: tr('Pengaturan'), subtitle: tr('PIN, anggaran, bahasa, backup'), chevron: true, onTap: () => context.push('/settings')),
          ListRow(
            icon: AppIcons.sparkles,
            iconColor: AppColors.amber,
            iconBackground: AppColors.amberSoft,
            title: tr('Plus berdua'),
            subtitle: tr('Trial 14 hari'),
            chevron: true,
            onTap: () => context.push('/paywall'),
          ),
          ListRow(icon: AppIcons.info, iconColor: AppColors.lilac, iconBackground: AppColors.lilacSoft, title: tr('Tentang'), trailingText: 'v${AppBrand.version}', trailingColor: AppColors.faint),
        ]),
      ],
    );
  }
}
