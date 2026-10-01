import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/maintenance_item_entity.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Rumah sehat: jadwal perawatan kendaraan, rumah, dan elektronik.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<CalendarViewModel>(
      create: (user) => CalendarViewModel(calendarRepository: buildCalendarRepository(), familyId: user.familyId),
      child: const _Content(),
    );
  }
}

// Template perawatan umum untuk rumah di Indonesia.
/// Nilai filter disimpan sebagai teks sumber, labelnya diterjemahkan saat tampil.
const _maintenanceFilters = ['Semua', 'Kendaraan', 'Rumah', 'Elektronik'];

const _templates = [
  ('Servis AC', 'elektronik', 'Cuci filter dan cek freon', 90, 250000.0),
  ('Kuras toren air', 'rumah', 'Tiap 6 bulan', 180, 150000.0),
  ('Ganti oli motor', 'kendaraan', 'Tiap 2.000 km', 60, 65000.0),
  ('Ganti filter air', 'rumah', 'Tiap 3 bulan', 90, 80000.0),
  ('Servis mobil', 'kendaraan', 'Tiap 10.000 km', 180, 850000.0),
  ('Cek tabung gas', 'rumah', 'Cek selang dan regulator', 90, 0.0),
];

class _Content extends StatelessWidget {
  const _Content();

  (IconData, Color, Color) _style(String status) {
    switch (status) {
      case 'Aman':
        return (AppIcons.circleCheck, AppColors.jade, AppColors.jadeSoft);
      case 'Terlambat':
      case 'Hari ini':
        return (AppIcons.circleAlert, AppColors.rose, AppColors.roseSoft);
      default:
        return (AppIcons.clock, AppColors.amber, AppColors.amberSoft);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'kendaraan':
        return AppIcons.bike;
      case 'elektronik':
        return AppIcons.airVent;
      default:
        return AppIcons.house;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final due = vm.dueThisMonth;
    final cost = due.fold(0.0, (s, m) => s + m.estimatedCost);
    final existingNames = vm.maintenanceItems.map((m) => m.name.toLowerCase()).toSet();
    final templates = _templates.where((t) => !existingNames.contains(tr(t.$1).toLowerCase())).take(3).toList();

    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        AppNavBar(title: tr('Rumah sehat'), actionIcon: AppIcons.plus, onAction: () => _addItem(context, vm)),
        SegmentedControl(
          labels: [for (final f in _maintenanceFilters) tr(f)],
          selected: _maintenanceFilters.indexOf(vm.maintenanceFilter).clamp(0, 3),
          onChanged: (i) => vm.setMaintenanceFilter(_maintenanceFilters[i]),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFFF7E3D2), Color(0xFFF6EBDD)]),
            border: Border.all(color: AppColors.glassEdge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(tr('BULAN INI'), style: AppText.eyebrow(AppColors.amber)),
              Text(due.isEmpty ? tr('Semua aman') : tr('{0} perlu dicek', [due.length]), style: AppText.display(24)),
              Text(
                due.isEmpty ? tr('Tidak ada jadwal perawatan sampai akhir bulan.') : tr('Estimasi {0}. Siapkan dari amplop Rumah & Tagihan.', [formatRupiahShort(cost)]),
                style: AppText.body(13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        ListCard(
          children: vm.filteredMaintenance.isEmpty
              ? [EmptyNote(tr('Belum ada jadwal perawatan. Mulai dari template di bawah.'))]
              : vm.filteredMaintenance.map((m) {
                  final status = vm.statusOf(m);
                  final s = _style(status);
                  return ListRow(
                    icon: _typeIcon(m.type),
                    iconColor: s.$2,
                    iconBackground: s.$3,
                    title: m.name,
                    subtitle: [
                      formatShortDate(m.nextServiceDate),
                      if (m.estimatedCost > 0) formatRupiahShort(m.estimatedCost),
                      if (m.note.isNotEmpty) m.note,
                    ].join(' · '),
                    trailing: Pill(tr(status), color: s.$2, background: s.$3),
                    onTap: () => _complete(context, vm, m),
                  );
                }).toList(),
        ),
        if (templates.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(tr('Mulai dari template'), style: AppText.body(15, weight: FontWeight.w700)),
                Text(tr('Jadwal perawatan umum untuk rumah di Indonesia.'), style: AppText.body(12, color: AppColors.muted)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: templates
                      .map((t) => GestureDetector(
                            onTap: () => vm.addMaintenance(name: tr(t.$1), type: t.$2, note: tr(t.$3), next: DateTime.now().add(Duration(days: t.$4)), cost: t.$5),
                            child: Pill('+ ${tr(t.$1)}'),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _complete(BuildContext context, CalendarViewModel vm, MaintenanceItemEntity m) async {
    final ok = await showConfirmDialog(
      context,
      title: tr('Sudah diservis?'),
      message: tr('{0} akan dijadwalkan lagi 3 bulan dari sekarang.', [m.name]),
      confirmLabel: tr('Tandai beres'),
      icon: AppIcons.wrench,
    );
    if (ok) await vm.completeMaintenance(m, 90);
  }

  Future<void> _addItem(BuildContext context, CalendarViewModel vm) async {
    final name = TextEditingController();
    final note = TextEditingController();
    final cost = TextEditingController();
    var type = 'rumah';
    var next = DateTime.now().add(const Duration(days: 30));
    await showAppSheet<void>(
      context,
      title: tr('Jadwal perawatan'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            AppTextField(controller: name, hint: tr('Misalnya: servis AC kamar'), autofocus: true),
            Wrap(
              spacing: 8,
              children: [('kendaraan', tr('Kendaraan')), ('rumah', tr('Rumah')), ('elektronik', tr('Elektronik'))]
                  .map((t) => ChoiceChip(label: Text(t.$2), selected: type == t.$1, onSelected: (_) => setState(() => type = t.$1), selectedColor: AppColors.jadeSoft))
                  .toList(),
            ),
            AppTextField(controller: note, hint: tr('Catatan, misalnya tiap 5.000 km')),
            AppTextField(controller: cost, hint: tr('Estimasi biaya (Rp)'), keyboardType: TextInputType.number),
            ListRow(
              icon: AppIcons.calendar,
              title: formatLongDate(next),
              subtitle: tr('Servis berikutnya'),
              chevron: true,
              onTap: () async {
                final p = await showDatePicker(context: context, initialDate: next, firstDate: DateTime.now(), lastDate: DateTime(2035));
                if (p != null) setState(() => next = p);
              },
            ),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await vm.addMaintenance(
                  name: name.text.trim(),
                  type: type,
                  note: note.text.trim(),
                  next: next,
                  cost: double.tryParse(cost.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
