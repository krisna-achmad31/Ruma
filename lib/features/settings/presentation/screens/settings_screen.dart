import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/app_locale.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_scope.dart';
import '../../../../core/theme/app_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _periods = ['bulanan', 'mingguan', 'kustom'];

  Future<void> _backup(BuildContext context, SettingsViewModel vm) async {
    final transactions = await buildFinanceRepository().watchTransactions(vm.familyId).first;
    final buffer = StringBuffer(tr('tanggal,judul,jenis,nominal,dicatat_oleh\n'));
    for (final t in transactions) {
      final title = t.title.replaceAll('"', '""');
      buffer.writeln('${dayKeyOf(t.date)},"$title",${t.isIncome ? 'masuk' : 'keluar'},${t.amount.round()},${t.createdByName ?? ''}');
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'text/csv', name: 'backup-${dayKeyOf(DateTime.now())}.csv')],
      fileNameOverrides: ['backup-${dayKeyOf(DateTime.now())}.csv'],
      text: tr('Backup transaksi rumah tangga'),
    ));
    await vm.markBackup();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = vm.settings;
    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        AppNavBar(title: tr('Pengaturan')),
        LabeledGroup(label: tr('Keamanan'), rows: [
          ListRow(
            icon: AppIcons.lockKeyhole,
            title: tr('PIN brankas'),
            subtitle: s.pinSet ? tr('Sudah disetel') : tr('Belum disetel'),
            trailingText: s.pinSet ? tr('Ubah') : tr('Setel'),
            trailingColor: AppColors.jade,
            onTap: () async {
              if (s.pinSet) {
                final ok = await showConfirmDialog(
                  context,
                  title: tr('Setel ulang PIN?'),
                  message: tr('PIN lama dihapus, lalu kamu diminta membuat PIN baru saat membuka Brankas.'),
                  confirmLabel: tr('Setel ulang'),
                  icon: AppIcons.lockKeyhole,
                );
                if (!ok) return;
                await vm.setPin(null);
              }
              if (context.mounted) context.push('/settings/important-links');
            },
          ),
          ListRow(
            icon: AppIcons.scanFace,
            title: tr('Buka pakai wajah / sidik jari'),
            trailing: GlassToggle(
              value: s.biometric,
              onChanged: (v) async {
                if (v && !await BiometricService().isAvailable()) {
                  if (context.mounted) showSnack(context, tr('Perangkat ini belum mendukung atau belum menyimpan sidik jari.'));
                  return;
                }
                await vm.setBiometric(v);
              },
            ),
          ),
        ]),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            GroupLabel(tr('Uang')),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(tr('Periode anggaran'), style: AppText.body(15, weight: FontWeight.w600)),
                  SegmentedControl(
                    labels: [tr('Bulanan'), tr('Mingguan'), tr('Kustom')],
                    selected: _periods.indexOf(s.budgetPeriodType).clamp(0, 2),
                    height: 38,
                    onChanged: (i) => vm.setBudgetPeriod(_periods[i]),
                  ),
                  ListRow(
                    icon: AppIcons.calendarSync,
                    title: tr('Amplop terisi ulang'),
                    subtitle: tr('Tiap tanggal gajian'),
                    trailingText: tr('Tgl {0}', [s.budgetResetDay]),
                    trailingColor: AppColors.jade,
                    onTap: () async {
                      final day = await showPickerSheet<int>(context, title: tr('Tanggal gajian'), items: List.generate(28, (i) => i + 1), label: (d) => tr('Tanggal {0}', [d]), selected: s.budgetResetDay);
                      if (day != null) await vm.setResetDay(day);
                    },
                  ),
                  const Divider(height: 1, color: AppColors.hairline),
                  ListRow(
                    icon: AppIcons.handCoins,
                    title: tr('Cara kelola uang'),
                    subtitle: s.moneyMode == 'gabung' ? tr('Semua dompet digabung jadi uang rumah') : tr('Sebagian dompet dipakai bersama'),
                    trailingText: s.moneyMode == 'gabung' ? tr('Digabung') : tr('Sebagian'),
                    trailingColor: AppColors.jade,
                    onTap: () async {
                      final mode = await showPickerSheet<String>(
                        context,
                        title: tr('Cara kelola uang'),
                        items: const ['gabung', 'sebagian'],
                        label: (m) => m == 'gabung' ? tr('Semua digabung (disarankan)') : tr('Sebagian digabung'),
                        sublabel: (m) => m == 'gabung' ? tr('Riset menunjukkan pasangan yang menggabungkan uang lebih puas.') : tr('Tiap orang tetap punya uang pribadi.'),
                        selected: s.moneyMode,
                      );
                      if (mode != null) await vm.setMoneyMode(mode);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        LabeledGroup(label: tr('Bahasa & wilayah'), rows: [
          ListRow(
            icon: AppIcons.languages,
            title: tr('Bahasa'),
            trailingText: AppLocale.instance.isEn ? 'English' : 'Indonesia',
            trailingColor: AppColors.muted,
            chevron: true,
            onTap: () async {
              final lang = await showPickerSheet<String>(context, title: tr('Bahasa'), items: AppLocale.supported, label: (l) => l == 'en' ? 'English' : 'Indonesia', selected: AppLocale.instance.code);
              if (lang != null) await AppLocale.instance.setCode(lang);
            },
          ),
          ListRow(
            icon: AppIcons.coins,
            title: tr('Mata uang'),
            trailingText: s.currency == 'IDR' ? tr('IDR (Rp)') : s.currency,
            trailingColor: AppColors.muted,
            chevron: true,
            onTap: () async {
              final c = await showPickerSheet<String>(context, title: tr('Mata uang'), items: const ['IDR', 'USD', 'SGD', 'MYR'], label: (c) => c, selected: s.currency);
              if (c != null) await vm.setCurrency(c);
            },
          ),
        ]),
        LabeledGroup(label: tr('Data'), rows: [
          ListRow(
            icon: AppIcons.sheet,
            title: tr('Backup ke CSV'),
            subtitle: s.lastBackupDate == null ? tr('Belum pernah backup') : tr('Terakhir {0}', [formatFullDate(s.lastBackupDate!)]),
            chevron: true,
            onTap: () => _backup(context, vm),
          ),
          ListRow(
            icon: AppIcons.trash2,
            iconColor: AppColors.rose,
            iconBackground: AppColors.roseSoft,
            title: tr('Reset semua data'),
            titleColor: AppColors.rose,
            subtitle: tr('Menghapus transaksi, jurnal, dan momen'),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: tr('Reset semua data?'),
                message: tr('Transaksi, jurnal, dan momen akan dihapus untuk semua anggota. Tindakan ini tidak bisa dibatalkan.'),
                confirmLabel: tr('Hapus semuanya'),
                icon: AppIcons.trash2,
                destructive: true,
              );
              if (!ok) return;
              await vm.resetData();
              if (context.mounted) showSnack(context, tr('Data sudah direset.'));
            },
          ),
        ]),
      ],
    );
  }
}
