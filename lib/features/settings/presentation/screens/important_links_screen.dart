import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/family_info_entity.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Brankas: nomor penting, dokumen, dan tautan keluarga. Terkunci PIN atau biometrik.
class ImportantLinksScreen extends StatelessWidget {
  const ImportantLinksScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    if (!vm.settings.pinSet) return SetPinScreenBody(title: tr('Buat PIN brankas'));
    if (!vm.vaultUnlocked) return _Locked(vm: vm);
    return _Unlocked(vm: vm);
  }
}

class _Locked extends StatelessWidget {
  final SettingsViewModel vm;

  const _Locked({required this.vm});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      children: [
        AppNavBar(title: tr('Brankas')),
        PinPad(
          title: tr('Masukkan PIN'),
          subtitle: tr('Brankas menyimpan nomor penting dan dokumen keluarga.'),
          onCompleted: (pin) async => vm.tryUnlock(pin),
          onBiometric: vm.settings.biometric
              ? () async {
                  if (await BiometricService().authenticate(tr('Buka brankas keluarga'))) vm.unlockWithoutPin();
                }
              : null,
        ),
      ],
    );
  }
}

class _Unlocked extends StatelessWidget {
  final SettingsViewModel vm;

  const _Unlocked({required this.vm});

  static const _groups = [
    ('nomor', 'Nomor penting', AppIcons.hash),
    ('dokumen', 'Dokumen & polis', AppIcons.fileText),
    ('link', 'Link & akun', AppIcons.link),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        AppNavBar(title: tr('Brankas'), actionIcon: AppIcons.plus, onAction: () => _add(context)),
        PastelHero(
          tone: PastelTone.lilac,
          object: 'key',
          objectSize: 104,
          objectRotation: -20,
          label: tr('Brankas terbuka'),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Text(tr('{0} catatan penting', [_groups.fold<int>(0, (s, g) => s + vm.vaultOf(g.$1).length)]), style: AppText.display(30, height: 1.05)),
            Text(tr('Nomor, dokumen, dan akun keluarga. Terkunci lagi otomatis dalam 1 menit.'), style: AppText.body(13, color: AppColors.muted, height: 1.4)),
          ]),
          body: Align(
            alignment: Alignment.centerLeft,
            child: Pill(tr('Hanya anggota keluarga'), icon: AppIcons.shieldCheck, color: PastelTone.lilac.label, background: const Color(0xCCFFFFFF)),
          ),
        ),
        for (final g in _groups)
          LabeledGroup(
            label: tr(g.$2),
            rows: vm.vaultOf(g.$1).isEmpty
                ? [EmptyNote(tr('Belum ada {0}.', [tr(g.$2).toLowerCase()]))]
                : vm.vaultOf(g.$1).map((item) => _row(context, item, g.$3)).toList(),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, VaultItemEntity item, IconData icon) {
    return ListRow(
      icon: icon,
      title: item.title,
      subtitle: item.masked,
      trailing: const Icon(AppIcons.copy, size: 16, color: AppColors.faint),
      onTap: () {
        Clipboard.setData(ClipboardData(text: item.value));
        showSnack(context, tr('{0} disalin.', [item.title]));
      },
    );
  }

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController();
    final value = TextEditingController();
    var group = 'nomor';
    await showAppSheet<void>(
      context,
      title: tr('Simpan ke brankas'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Wrap(
              spacing: 8,
              children: _groups
                  .map((g) => ChoiceChip(label: Text(tr(g.$2)), selected: group == g.$1, onSelected: (_) => setState(() => group = g.$1), selectedColor: AppColors.jadeSoft))
                  .toList(),
            ),
            AppTextField(controller: title, hint: tr('Nama, misalnya ID pelanggan PLN'), autofocus: true),
            AppTextField(controller: value, hint: tr('Isi, misalnya nomor atau tautan')),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                if (title.text.trim().isEmpty || value.text.trim().isEmpty) return;
                await vm.addVaultItem(group, title.text.trim(), value.text.trim());
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Alur buat atau ubah PIN: isi 6 angka lalu ulangi untuk konfirmasi.
class SetPinScreenBody extends StatefulWidget {
  final String title;

  const SetPinScreenBody({super.key, required this.title});

  @override
  State<SetPinScreenBody> createState() => _SetPinScreenBodyState();
}

class _SetPinScreenBodyState extends State<SetPinScreenBody> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SettingsViewModel>();
    return AppScaffold(
      children: [
        AppNavBar(title: tr('Setel PIN')),
        PinPad(
          key: ValueKey(_first == null),
          title: _first == null ? widget.title : tr('Ulangi PIN'),
          subtitle: _first == null ? tr('6 angka untuk membuka nomor penting dan dokumen keluarga.') : tr('Masukkan lagi 6 angka yang sama.'),
          onCompleted: (pin) async {
            if (_first == null) {
              setState(() => _first = pin);
              return true;
            }
            if (pin != _first) {
              setState(() => _first = null);
              if (context.mounted) showSnack(context, tr('PIN tidak sama. Ulangi dari awal.'));
              return false;
            }
            await vm.setPin(pin);
            vm.unlockWithoutPin();
            if (context.mounted) showSnack(context, tr('PIN brankas tersimpan.'));
            return true;
          },
        ),
      ],
    );
  }
}
