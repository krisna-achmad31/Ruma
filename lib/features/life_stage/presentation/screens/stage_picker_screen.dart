import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../settings/presentation/widgets/settings_scope.dart';
import '../../domain/entities/family_stage.dart';

/// Pilih fase hidup keluarga. Muncul sebagai langkah terakhir onboarding dan bisa diubah dari Rumah.
class StagePickerScreen extends StatelessWidget {
  final bool fromOnboarding;

  const StagePickerScreen({super.key, this.fromOnboarding = false});

  @override
  Widget build(BuildContext context) => SettingsScope(child: _Content(fromOnboarding: fromOnboarding));
}

class _Content extends StatefulWidget {
  final bool fromOnboarding;

  const _Content({required this.fromOnboarding});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  String? _picked;
  bool _saving = false;

  static final _options = [
    (FamilyStage.wedding, 'ring', AppColors.roseSoft, 'Siap nikah', 'Menyiapkan akad & resepsi'),
    (FamilyStage.newlywed, 'house', AppColors.jadeSoft, 'Baru menikah', 'Belajar ngatur rumah berdua'),
    (FamilyStage.expecting, 'baby_bottle', AppColors.skySoft, 'Menanti bayi', 'Persalinan & perlengkapan'),
    (FamilyStage.parents, 'backpack', AppColors.butterSoft, 'Sudah punya anak', 'Sekolah, jajan, jaga malam'),
  ];

  void _leave() {
    if (widget.fromOnboarding) {
      context.go('/paywall?from=onboarding');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/more');
    }
  }

  Future<void> _save(SettingsViewModel vm, String stage) async {
    setState(() => _saving = true);
    final ok = await saveOrWarn(context, vm.setLifeStage(stage));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final current = _picked ?? (vm.familyInfo.lifeStage.isEmpty ? null : vm.familyInfo.lifeStage);

    return AppScaffold(
      gap: 22,
      bottom: PrimaryButton(
        label: widget.fromOnboarding ? tr('Lanjut') : tr('Simpan'),
        loading: _saving,
        onPressed: current == null ? null : () => _save(vm, current),
      ),
      children: [
        if (widget.fromOnboarding)
          Row(children: [
            Expanded(child: Text(tr('Langkah 3 dari 3'), style: AppText.navTitle)),
            GestureDetector(onTap: _leave, child: Text(tr('Lewati'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.muted))),
          ])
        else
          AppNavBar(title: tr('Fase kalian')),
        Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
          Text(tr('Kalian lagi di fase apa?'), style: AppText.display(32, letterSpacing: -1, height: 1.08)),
          Text(tr('Biar Hari ini menampilkan yang paling kepake buat kalian. Bisa diganti kapan saja.'), style: AppText.body(15, color: AppColors.muted, height: 1.45)),
        ]),
        for (int r = 0; r < 2; r++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              for (final o in _options.skip(r * 2).take(2))
                Expanded(child: _StageTile(option: o, selected: current == o.$1, onTap: () => setState(() => _picked = o.$1))),
            ]),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: const Color(0x80FBEFC8), borderRadius: BorderRadius.circular(18)),
          child: Row(spacing: 10, children: [
            const Object3D('crescent_moon', size: 26),
            Expanded(child: Text(tr('Lebaran & THR muncul otomatis menjelang Ramadan, apa pun fasenya.'), style: AppText.body(12, color: AppColors.muted, height: 1.35))),
          ]),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final (String, String, Color, String, String) option;
  final bool selected;
  final VoidCallback onTap;

  const _StageTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      strong: selected,
      radius: 26,
      padding: const EdgeInsets.all(16),
      borderColor: selected ? AppColors.jade : null,
      borderWidth: selected ? 2 : 1,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: option.$3, borderRadius: BorderRadius.circular(22)),
            child: Object3D(option.$2, size: 48),
          ),
          const Spacer(),
          if (selected) const CheckCircle(checked: true),
        ]),
        const SizedBox(height: 24),
        Text(tr(option.$4), style: AppText.body(15, weight: FontWeight.w700)),
        Text(tr(option.$5), style: AppText.body(12, color: AppColors.muted, height: 1.3)),
      ]),
    );
  }
}
