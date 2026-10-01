import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Aset, utang, dan piutang keluarga.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _groups = [
    ('aset', 'Aset & investasi', AppIcons.sprout, AppColors.amber, AppColors.amberSoft, AppColors.ink),
    ('utang', 'Utang', AppIcons.creditCard, AppColors.rose, AppColors.roseSoft, AppColors.rose),
    ('piutang', 'Piutang', AppIcons.handCoins, AppColors.jade, AppColors.jadeSoft, AppColors.jade),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(title: tr('Utang & aset'), actionIcon: AppIcons.plus, onAction: () => _add(context, vm)),
        SegmentedControl(
          labels: [tr('Belanja'), tr('Tabungan'), tr('Utang & aset')],
          selected: 2,
          onChanged: (i) {
            if (i == 0) context.pushReplacement('/finance/categories');
            if (i == 1) context.pushReplacement('/finance/goals');
          },
        ),
        PastelHero(
          tone: PastelTone.sky,
          object: 'banknote',
          objectSize: 104,
          objectRotation: -8,
          label: tr('Aset dikurangi utang'),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            HeroNumber(formatRupiah(vm.assetNet), size: 32),
            Text(tr('Ikut dihitung di Rekap sebagai kekayaan bersih.'), style: AppText.body(13, color: AppColors.muted, height: 1.4)),
          ]),
        ),
        for (final g in _groups)
          LabeledGroup(
            label: tr(g.$2),
            rows: vm.assetsOf(g.$1).isEmpty
                ? [EmptyNote(tr('Belum ada {0}.', [tr(g.$2).toLowerCase()]))]
                : vm
                    .assetsOf(g.$1)
                    .map((a) => ListRow(
                          icon: g.$3,
                          iconColor: g.$4,
                          iconBackground: g.$5,
                          title: a.name,
                          subtitle: a.note.isEmpty ? null : a.note,
                          trailingText: formatRupiah(a.value),
                          trailingColor: g.$6,
                        ))
                    .toList(),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, FinanceViewModel vm) async {
    final name = TextEditingController();
    final note = TextEditingController();
    final value = TextEditingController();
    var kind = 'aset';
    await showAppSheet<void>(
      context,
      title: tr('Catat aset atau utang'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Wrap(
              spacing: 8,
              children: [('aset', tr('Aset')), ('utang', tr('Utang')), ('piutang', tr('Piutang'))]
                  .map((k) => ChoiceChip(label: Text(tr(k.$2)), selected: kind == k.$1, onSelected: (_) => setState(() => kind = k.$1), selectedColor: AppColors.jadeSoft))
                  .toList(),
            ),
            AppTextField(controller: name, hint: tr('Nama, misalnya Emas 8 gram'), autofocus: true),
            AppTextField(controller: value, hint: tr('Nilai (Rp)'), keyboardType: TextInputType.number),
            AppTextField(controller: note, hint: tr('Catatan, misalnya janji dikembalikan Des')),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                final v = double.tryParse(value.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
                if (name.text.trim().isEmpty || v <= 0) return;
                await vm.addAsset(name.text.trim(), v, kind, note.text.trim());
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
