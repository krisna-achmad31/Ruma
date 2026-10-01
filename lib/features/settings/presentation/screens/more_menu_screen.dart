import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../life_stage/domain/entities/family_stage.dart';
import '../../../life_stage/presentation/viewmodels/life_stage_viewmodel.dart';
import '../../../life_stage/presentation/widgets/life_stage_scope.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Tab Rumah: fase hidup di paling atas, lalu alat rumah tangga, Plus, dan akun.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScope(child: LifeStageScope(child: _Content()));
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        _Header(vm: vm),
        const _LifeStages(),
        const _Tools(),
        const _PlusCard(),
        LabeledGroup(label: tr('Akun'), rows: [
          ListRow(icon: AppIcons.user, iconColor: AppColors.sky, iconBackground: AppColors.fieldFill, title: tr('Profil'), chevron: true, onTap: () => context.push('/settings/profile')),
          ListRow(icon: AppIcons.settings, iconBackground: AppColors.fieldFill, title: tr('Pengaturan'), subtitle: tr('PIN, anggaran, bahasa, backup'), chevron: true, onTap: () => context.push('/settings')),
          ListRow(icon: AppIcons.info, iconBackground: AppColors.fieldFill, title: tr('Tentang'), trailingText: 'v${AppBrand.version}', trailingColor: AppColors.faint),
        ]),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final SettingsViewModel vm;

  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    final info = vm.familyInfo;
    const colors = [AppColors.jade, AppColors.rose, AppColors.amber];
    final count = vm.members.length.clamp(0, 3);
    final line = [info.name.isEmpty ? tr('Rumah kita') : info.name, if (info.location.isNotEmpty) info.location].join(', ');
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(tr('Rumah'), style: AppText.largeTitle),
              Row(
                spacing: 8,
                children: [
                  if (count > 0)
                    SizedBox(
                      width: 24.0 + (count - 1) * 16,
                      height: 24,
                      child: Stack(
                        children: List.generate(count, (i) => Positioned(left: i * 16.0, child: Avatar(name: vm.members[i].name, color: colors[i % 3], size: 24, ring: true))),
                      ),
                    ),
                  Expanded(child: Text(line, style: AppText.body(12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
        GlassCard(
          onTap: () => context.push('/invite'),
          radius: 22,
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(spacing: 6, children: [
            const Object3D('wave', size: 28),
            Text(tr('Undang'), style: AppText.body(13, weight: FontWeight.w700)),
          ]),
        ),
      ],
    );
  }
}

/// Kartu fase hidup yang bisa digeser. Fase yang sudah berjalan tampil paling depan.
class _LifeStages extends StatelessWidget {
  const _LifeStages();

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeStageViewModel>();
    final cards = <_StageCard>[
      _StageCard(
        tone: PastelTone.butter,
        object: 'crescent_moon',
        title: tr('Lebaran & THR'),
        hook: tr('Rencana THR, salam tempel, checklist mudik.'),
        status: life.lebaran == null ? tr('Untuk semua keluarga') : tr('{0} hari lagi', [life.daysUntil(life.lebaran!.eidDate).clamp(0, 9999)]),
        active: life.lebaran != null,
        route: '/life/lebaran',
      ),
      _StageCard(
        tone: PastelTone.rose,
        object: 'ring',
        title: tr('Siap nikah'),
        hook: tr('Anggaran nikah, bayar vendor, obrolan pranikah.'),
        status: life.wedding == null ? tr('Untuk yang mau akad') : tr('{0} hari ke akad', [life.daysUntil(life.wedding!.weddingDate).clamp(0, 9999)]),
        active: life.wedding != null,
        route: '/life/wedding',
      ),
      _StageCard(
        tone: PastelTone.sky,
        object: 'baby_bottle',
        title: tr('Menyambut bayi'),
        hook: tr('Persalinan, perlengkapan, gantian jaga malam.'),
        status: life.baby == null ? tr('Untuk yang menanti') : tr('Minggu ke-{0}', [life.baby!.weekOf(DateTime.now())]),
        active: life.baby != null,
        route: '/life/baby',
      ),
    ];
    final preferred = FamilyStage.planFor(context.watch<SettingsViewModel>().familyInfo.lifeStage);
    int rank(_StageCard c) => (c.active ? 2 : 0) + (c.route.endsWith(preferred) ? 1 : 0);
    cards.sort((a, b) => rank(b) - rank(a));

    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Row(spacing: 8, children: [
              Text(tr('Fase hidup'), style: AppText.sectionTitle),
              const PlusBadge(),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/life/stage'),
                child: Text(tr('Ubah fase'), style: AppText.body(14, weight: FontWeight.w600, color: AppColors.jade)),
              ),
            ]),
            Text(tr('Pendamping di momen paling sibuk kalian'), style: AppText.body(12, color: AppColors.muted)),
          ],
        ),
        SizedBox(
          height: 236,
          child: OverflowBox(
            maxWidth: width,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => cards[i],
            ),
          ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final PastelTone tone;
  final String object;
  final String title;
  final String hook;
  final String status;
  final bool active;
  final String route;

  const _StageCard({required this.tone, required this.object, required this.title, required this.hook, required this.status, required this.active, required this.route});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: 236,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone.colors),
          border: Border.all(color: const Color(0xB3FFFFFF)),
          boxShadow: [BoxShadow(color: tone.accent.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned(right: -8, top: -10, child: Object3D(object, size: 112, rotation: -12)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 6,
                  children: [
                    if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xCCFFFFFF), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.jade, shape: BoxShape.circle)),
                          Text(status, style: AppText.body(11, weight: FontWeight.w700, color: AppColors.jade)),
                        ]),
                      )
                    else
                      Text(status, style: AppText.body(11, weight: FontWeight.w700, color: tone.label)),
                    Text(title, style: AppText.display(22, letterSpacing: -0.5)),
                    Text(hook, style: AppText.body(12, color: AppColors.muted, height: 1.35), maxLines: 2),
                    const SizedBox(height: 2),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: active ? AppColors.ink : const Color(0xD9FFFFFF), borderRadius: BorderRadius.circular(19)),
                      child: Text(
                        active ? tr('Lanjutkan rencana') : tr('Mulai, gratis 14 hari'),
                        style: AppText.body(12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools();

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('hammer_wrench', tr('Rumah sehat'), '/more/maintenance'),
      ('bank', tr('Dompet'), '/finance/wallets'),
      ('locked', tr('Brankas'), '/settings/important-links'),
      ('bar_chart', tr('Rekap'), '/finance/report'),
      ('notebook', tr('Jurnal'), '/together/journal'),
      ('shopping_cart', tr('Belanja'), '/urusan/shopping'),
      ('calendar', tr('Kalender'), '/urusan/calendar'),
      ('mobile_phone', tr('Widget'), '/more/widget'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text(tr('Kelola rumah'), style: AppText.sectionTitle),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              for (int r = 0; r < 2; r++)
                Row(
                  children: [
                    for (final t in tools.skip(r * 4).take(4))
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push(t.$3),
                          child: Column(
                            spacing: 6,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xE6FFFFFF),
                                  borderRadius: BorderRadius.circular(19),
                                  border: Border.all(color: AppColors.glassEdge),
                                  boxShadow: const [BoxShadow(color: Color(0x1215201D), blurRadius: 12, offset: Offset(0, 4))],
                                ),
                                child: Object3D(t.$1, size: 38),
                              ),
                              Text(t.$2, style: AppText.body(12, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlusCard extends StatelessWidget {
  const _PlusCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF15201D), Color(0xFF24352F)]),
        ),
        child: Row(
          spacing: 14,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(spacing: 6, children: [
                    const Object3D('sparkles', size: 22),
                    Text(tr('Plus berdua'), style: AppText.display(17, color: Colors.white)),
                  ]),
                  Text(
                    tr('Semua fase hidup, cicilan, rapor, dan brankas. Satu langganan untuk berdua.'),
                    style: AppText.body(12, color: const Color(0xB3FFFFFF), height: 1.4),
                  ),
                ],
              ),
            ),
            HeroButton(label: tr('Coba gratis'), light: true, onTap: () => context.push('/paywall')),
          ],
        ),
      ),
    );
  }
}
