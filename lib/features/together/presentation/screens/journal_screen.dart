import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _filters = ['Semua', 'Cerita', 'Makasih'];

  String _when(DateTime date, String time) {
    final label = relativeDayLabel(date);
    final day = label == tr('Hari ini') || label == tr('Kemarin') ? label : formatShortDate(date);
    return time.isEmpty ? day : '$day, ${time.replaceAll(':', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(title: tr('Jurnal keluarga'), actionIcon: AppIcons.plus, onAction: () => showJournalSheet(context, vm)),
        GlassCard(
          radius: 26,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          onTap: () => showJournalSheet(context, vm),
          child: Row(spacing: 10, children: [
            Avatar(name: vm.firstName, size: 30),
            Expanded(child: Text(tr('Cerita apa hari ini?'), style: AppText.body(14, color: AppColors.faint))),
            GestureDetector(
              onTap: () => showJournalSheet(context, vm, thanks: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisSize: MainAxisSize.min, spacing: 5, children: [
                  const Icon(AppIcons.heartHandshake, size: 14, color: AppColors.rose),
                  Text(tr('Makasih'), style: AppText.body(12, weight: FontWeight.w700, color: AppColors.rose)),
                ]),
              ),
            ),
          ]),
        ),
        SegmentedControl(
          labels: [for (final f in _filters) tr(f)],
          selected: _filters.indexOf(vm.journalFilter),
          selectedTextColor: AppColors.rose,
          onChanged: (i) => vm.setJournalFilter(_filters[i]),
        ),
        if (vm.filteredJournal.isEmpty) GlassCard(child: EmptyNote(tr('Belum ada entri di sini.'), icon: AppIcons.bookHeart)),
        ...vm.filteredJournal.map((j) {
          final mine = j.authorUid == vm.uid;
          final card = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(spacing: 10, children: [
                Avatar(name: j.authorName, color: mine ? AppColors.jade : AppColors.rose),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                    Text(j.authorName.split(' ').first, style: AppText.body(13, weight: FontWeight.w700)),
                    Text(_when(j.date, j.time), style: AppText.body(11, color: AppColors.muted)),
                  ]),
                ),
                if (j.isThanks) const Icon(AppIcons.heartHandshake, size: 18, color: AppColors.rose),
              ]),
              Text(j.title, style: AppText.body(16, weight: FontWeight.w700)),
              if (j.text.isNotEmpty) Text(j.text, style: AppText.body(14, color: AppColors.muted, height: 1.4)),
            ],
          );
          return j.isThanks
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.glassEdge)),
                  child: card,
                )
              : GlassCard(padding: const EdgeInsets.all(16), child: card);
        }),
      ],
    );
  }
}

/// Sheet tulis cerita atau ucapan makasih.
Future<void> showJournalSheet(BuildContext context, TogetherViewModel vm, {bool thanks = false}) {
  final title = TextEditingController(text: thanks ? tr('Makasih udah ') : '');
  final text = TextEditingController();
  var isThanks = thanks;
  return showAppSheet<void>(
    context,
    title: isThanks ? tr('Bilang makasih') : tr('Tulis cerita'),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: 8,
            children: [(false, tr('Cerita'), AppIcons.bookOpen), (true, tr('Makasih'), AppIcons.heartHandshake)].map((o) {
              final sel = isThanks == o.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isThanks = o.$1),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: sel ? AppColors.ink : const Color(0x0D15201D), borderRadius: BorderRadius.circular(21)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [
                      Icon(o.$3, size: 15, color: sel ? Colors.white : AppColors.ink),
                      Text(o.$2, style: AppText.body(13, weight: FontWeight.w700, color: sel ? Colors.white : AppColors.ink)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          LabeledField(label: tr('Judul'), child: AppTextField(controller: title, hint: isThanks ? tr('Makasih udah bayar listrik') : tr('Kia belajar naik sepeda'), autofocus: true)),
          LabeledField(label: isThanks ? tr('Pesan (opsional)') : tr('Cerita'), child: AppTextField(controller: text, maxLines: 4, hint: tr('Tulis di sini'))),
          PrimaryButton(
            label: tr('Simpan ke jurnal'),
            height: 52,
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              await vm.addJournalEntry(title: title.text.trim(), text: text.text.trim(), type: isThanks ? 'makasih' : 'cerita');
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    ),
  );
}
