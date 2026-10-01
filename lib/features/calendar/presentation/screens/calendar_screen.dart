import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../domain/entities/calendar_event_entity.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<CalendarViewModel>(
      create: (user) => CalendarViewModel(calendarRepository: buildCalendarRepository(), familyId: user.familyId)..selectDay(dateOnly(DateTime.now())),
      child: const _Content(),
    );
  }
}

(IconData, Color, Color) _styleOf(String category) {
  switch (category) {
    case 'bayar_belanja':
      return (AppIcons.receipt, AppColors.amber, AppColors.amberSoft);
    case 'maintenance':
      return (AppIcons.wrench, AppColors.jade, AppColors.jadeSoft);
    case 'berdua':
      return (AppIcons.heart, AppColors.rose, AppColors.roseSoft);
    default:
      return (AppIcons.calendarCheck, AppColors.jade, AppColors.jadeSoft);
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final day = vm.selectedDay ?? dateOnly(DateTime.now());
    final agenda = vm.eventsOnDay(day);
    final bills = vm.billEvents.where((e) => e.date.month == vm.displayedMonth.month && e.date.year == vm.displayedMonth.year).toList();

    return AppScaffold(
      tab: AppTab.urusan,
      children: [
        AppNavBar(title: tr('Kalender'), actionIcon: AppIcons.plus, onAction: () => _addEvent(context, vm, day)),
        Row(
          children: [
            Expanded(child: Text('${monthNamesId[vm.displayedMonth.month - 1]} ${vm.displayedMonth.year}', style: AppText.display(28, letterSpacing: -0.7))),
            GlassCircleButton(icon: AppIcons.chevronLeft, size: 34, onTap: vm.previousMonth),
            const SizedBox(width: 8),
            GlassCircleButton(icon: AppIcons.chevronRight, size: 34, onTap: vm.nextMonth),
          ],
        ),
        _MonthGrid(vm: vm),
        Text(formatLongDate(day), style: AppText.sectionTitle),
        ListCard(
          children: agenda.isEmpty
              ? [EmptyNote(tr('Tidak ada agenda di hari ini.'))]
              : agenda.map((e) {
                  final s = _styleOf(e.category);
                  return ListRow(
                    icon: s.$1,
                    iconColor: s.$2,
                    iconBackground: s.$3,
                    title: e.title,
                    subtitle: e.isDone ? tr('Sudah beres') : tr('Ketuk untuk tandai beres'),
                    titleColor: e.isDone ? AppColors.faint : AppColors.ink,
                    trailing: CheckCircle(checked: e.isDone, size: 22),
                    onTap: () => vm.toggleEventDone(e),
                  );
                }).toList(),
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const IconBox(icon: AppIcons.receipt, size: 32, color: AppColors.jade),
                    Text(tr('Bayar & belanja'), style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted)),
                    Text(tr('{0} dari {1} beres', [bills.where((b) => b.isDone).length, bills.length]), style: AppText.body(15, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/more/maintenance'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const IconBox(icon: AppIcons.wrench, size: 32, color: AppColors.amber, background: AppColors.amberSoft),
                    Text(tr('Rumah sehat'), style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted)),
                    Text(tr('{0} perlu dicek', [vm.maintenanceDueSoonCount]), style: AppText.body(15, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (bills.isNotEmpty)
          InfoBanner(
            icon: AppIcons.repeat,
            text: tr('Tagihan rutin bulan ini: {0}.', [bills.map((b) => b.title.toLowerCase()).take(3).join(', ')]),
          ),
      ],
    );
  }

  Future<void> _addEvent(BuildContext context, CalendarViewModel vm, DateTime day) async {
    final title = TextEditingController();
    var category = 'bayar_belanja';
    var date = day;
    await showAppSheet<void>(
      context,
      title: tr('Agenda baru'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            AppTextField(controller: title, hint: tr('Misalnya: bayar internet'), autofocus: true),
            Wrap(
              spacing: 8,
              children: [('bayar_belanja', tr('Bayar & belanja')), ('maintenance', tr('Rumah sehat')), ('berdua', tr('Berdua'))].map((c) {
                final sel = c.$1 == category;
                return ChoiceChip(
                  label: Text(c.$2),
                  selected: sel,
                  onSelected: (_) => setState(() => category = c.$1),
                  selectedColor: AppColors.jadeSoft,
                );
              }).toList(),
            ),
            ListRow(
              icon: AppIcons.calendar,
              title: formatLongDate(date),
              subtitle: tr('Tanggal'),
              chevron: true,
              onTap: () async {
                final p = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2035));
                if (p != null) setState(() => date = p);
              },
            ),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await vm.addEvent(title.text.trim(), category, date);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final CalendarViewModel vm;

  const _MonthGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    final first = vm.displayedMonth;
    final offset = first.weekday - 1;
    final start = first.subtract(Duration(days: offset));
    final weeks = ((offset + DateTime(first.year, first.month + 1, 0).day) / 7).ceil();
    final today = dateOnly(DateTime.now());

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      child: Column(
        spacing: 4,
        children: [
          Row(
            children: shortDayNamesId
                .map((d) => Expanded(child: Center(child: Text(d, style: AppText.body(11, weight: FontWeight.w700, color: AppColors.faint)))))
                .toList(),
          ),
          const SizedBox(height: 4),
          for (int w = 0; w < weeks; w++)
            Row(
              children: List.generate(7, (i) {
                final d = start.add(Duration(days: w * 7 + i));
                final inMonth = d.month == first.month;
                final selected = vm.selectedDay != null && isSameDay(d, vm.selectedDay!);
                final events = vm.eventsOnDay(d);
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => vm.selectDay(d),
                    child: SizedBox(
                      height: 46,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.ink : Colors.transparent,
                              shape: BoxShape.circle,
                              border: !selected && isSameDay(d, today) ? Border.all(color: AppColors.jade) : null,
                            ),
                            child: Text(
                              '${d.day}',
                              style: AppText.body(14,
                                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? Colors.white : (inMonth ? AppColors.ink : const Color(0x4015201D))),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 3,
                              children: events.take(3).map((CalendarEventEntity e) {
                                return Container(width: 5, height: 5, decoration: BoxDecoration(color: _styleOf(e.category).$2, shape: BoxShape.circle));
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
