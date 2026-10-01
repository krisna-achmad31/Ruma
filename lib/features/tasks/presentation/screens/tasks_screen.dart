import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/task_entity.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class TasksScreen extends StatelessWidget {
  final bool openAdd;

  const TasksScreen({super.key, this.openAdd = false});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<TasksViewModel>(
      create: (user) => TasksViewModel(
        taskRepository: buildTaskRepository(),
        settingsRepository: buildSettingsRepository(),
        togetherRepository: buildTogetherRepository(),
        homeRepository: buildHomeRepository(),
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: _Content(openAdd: openAdd),
    );
  }
}

class _Content extends StatefulWidget {
  final bool openAdd;

  const _Content({required this.openAdd});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAddTaskSheet(context, context.read<TasksViewModel>());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final groups = vm.grouped;
    return AppScaffold(
      tab: AppTab.urusan,
      children: [
        LargeTitle(
          title: tr('Urusan'),
          subtitle: AppBrand.taglineId,
          trailing: Row(
            spacing: 8,
            children: [
              GlassCircleButton(icon: AppIcons.calendarDays, size: 44, onTap: () => context.push('/urusan/calendar')),
              GlassCircleButton(icon: AppIcons.plus, size: 44, onTap: () => showAddTaskSheet(context, vm)),
            ],
          ),
        ),
        SegmentedControl(labels: [tr('Minggu ini'), tr('Rutin'), tr('Selesai')], selected: vm.segment, onChanged: vm.setSegment),
        if (vm.segment == 0 && vm.invisibleWork.isNotEmpty) _InvisibleWork(vm: vm),
        Row(
          spacing: 8,
          children: [
            ShortcutTile(label: tr('Belanja'), icon: AppIcons.shoppingCart, tone: toneAmber, onTap: () => context.push('/urusan/shopping')),
            ShortcutTile(label: tr('Kalender'), icon: AppIcons.calendarDays, tone: toneSky, onTap: () => context.push('/urusan/calendar')),
            ShortcutTile(label: tr('Rumah sehat'), icon: AppIcons.wrench, tone: toneLilac, onTap: () => context.push('/more/maintenance')),
          ],
        ),
        if (groups.isEmpty)
          GlassCard(child: EmptyNote(tr('Belum ada urusan di sini. Tambah dengan tombol + di atas.')))
        else
          ...groups.entries.map(
            (g) => LabeledGroup(label: g.key, rows: g.value.map((t) => _TaskRow(task: t, vm: vm)).toList()),
          ),
      ],
    );
  }
}

class _InvisibleWork extends StatelessWidget {
  final TasksViewModel vm;

  const _InvisibleWork({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.invisibleWork;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.warmGradient),
        border: Border.all(color: AppColors.glassEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(spacing: 10, children: [
            const Icon(AppIcons.brain, size: 20, color: AppColors.rose),
            Text(tr('Yang dipikirin diam-diam'), style: AppText.body(15, weight: FontWeight.w700)),
          ]),
          Text(
            tr('Minggu ini {0} yang ingat hal-hal ini. Kecil, tapi bikin rumah tetap jalan.', [vm.partnerName]),
            style: AppText.body(13, color: AppColors.muted, height: 1.4),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
                        Icon(iconFor(t.icon), size: 15, color: AppColors.rose),
                        Text(t.title, style: AppText.body(13, weight: FontWeight.w500)),
                      ]),
                    ))
                .toList(),
          ),
          PrimaryButton(
            label: tr('Bilang makasih ke {0}', [vm.partnerName]),
            icon: AppIcons.heartHandshake,
            height: 44,
            onPressed: () async {
              await vm.sendThanks(tr('Makasih udah ingat {0}', [items.first.title.toLowerCase()]));
              if (context.mounted) showSnack(context, tr('Ucapan makasih terkirim ke {0}.', [vm.partnerName]));
            },
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskEntity task;
  final TasksViewModel vm;

  const _TaskRow({required this.task, required this.vm});

  Widget _role(IconData icon, String text, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
          Icon(icon, size: 12, color: color),
          Text(text, style: AppText.body(11, weight: FontWeight.w600, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final thinker = vm.isMe(task.thinkerUid) ? tr('Kamu ingat') : tr('{0} ingat', [vm.firstNameOf(task.thinkerName)]);
    Widget doer;
    if (task.together) {
      doer = _role(AppIcons.hand, tr('Dikerjakan berdua'), AppColors.jade, AppColors.jadeSoft);
    } else if (task.doerUid == null) {
      doer = GestureDetector(
        onTap: () => vm.takeOver(task),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.amber)),
          child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
            const Icon(AppIcons.handHelping, size: 12, color: AppColors.amber),
            Text(tr('Siapa yang ambil?'), style: AppText.body(11, weight: FontWeight.w700, color: AppColors.amber)),
          ]),
        ),
      );
    } else {
      final who = vm.isMe(task.doerUid) ? tr('Kamu kerjakan') : tr('{0} kerjakan', [vm.firstNameOf(task.doerName)]);
      doer = _role(AppIcons.hand, who, AppColors.jade, AppColors.jadeSoft);
    }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        child: const Icon(AppIcons.trash2, color: AppColors.rose, size: 18),
      ),
      confirmDismiss: (_) => showConfirmDialog(context, title: tr('Hapus urusan ini?'), message: task.title, confirmLabel: tr('Hapus'), destructive: true, icon: AppIcons.trash2),
      onDismissed: (_) => vm.delete(task),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          spacing: 12,
          children: [
            CheckCircle(checked: task.isDone, onTap: () => vm.toggle(task)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    task.title,
                    style: AppText.body(15,
                        weight: FontWeight.w600,
                        color: task.isDone ? AppColors.faint : AppColors.ink,
                        decoration: task.isDone ? TextDecoration.lineThrough : null),
                  ),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _role(AppIcons.brain, thinker, AppColors.rose, AppColors.roseSoft),
                    doer,
                  ]),
                ],
              ),
            ),
            if (task.time != null) Text(task.time!, style: AppText.body(12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Sheet tambah urusan: judul, siapa yang kerjakan, tanggal, dan apakah rutin.
Future<void> showAddTaskSheet(BuildContext context, TasksViewModel vm) {
  final title = TextEditingController();
  var doer = 'me';
  DateTime? due = DateTime.now();
  var routine = false;
  return showAppSheet<void>(
    context,
    title: tr('Urusan baru'),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        Widget choice(String key, String label) {
          final sel = doer == key;
          return GestureDetector(
            onTap: () => setState(() => doer = key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: sel ? AppColors.ink : const Color(0x0D15201D), borderRadius: BorderRadius.circular(18)),
              child: Text(label, style: AppText.body(13, weight: FontWeight.w700, color: sel ? Colors.white : AppColors.ink)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            AppTextField(controller: title, hint: tr('Misalnya: beli galon'), autofocus: true),
            Text(tr('Kamu yang ingat. Siapa yang kerjakan?'), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
            Wrap(spacing: 8, runSpacing: 8, children: [
              choice('me', tr('Aku')),
              choice('partner', vm.partnerName),
              choice('together', tr('Berdua')),
              choice('none', tr('Belum tahu')),
            ]),
            ListRow(
              icon: AppIcons.calendar,
              title: due == null ? tr('Tanpa tanggal') : formatLongDate(due!),
              subtitle: tr('Tanggal'),
              chevron: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: due ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => due = picked);
              },
            ),
            Row(children: [
              Expanded(child: Text(tr('Urusan rutin'), style: AppText.body(15, weight: FontWeight.w600))),
              GlassToggle(value: routine, onChanged: (v) => setState(() => routine = v)),
            ]),
            PrimaryButton(
              label: tr('Simpan'),
              height: 52,
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await vm.addTask(title: title.text.trim(), doer: doer, dueDate: due, routine: routine);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}
