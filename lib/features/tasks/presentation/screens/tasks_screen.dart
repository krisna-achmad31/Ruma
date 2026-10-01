import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/pastel_hero.dart';
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
          subtitle: tr('Siapa yang ingat, siapa yang kerjakan.'),
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
            (g) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(spacing: 8, children: [
                  Text(g.key, style: AppText.display(18, letterSpacing: -0.3)),
                  Text(tr('{0} urusan', [g.value.length]), style: AppText.body(12, weight: FontWeight.w600, color: AppColors.faint)),
                ]),
                ListCard(children: g.value.map((t) => _TaskRow(task: t, vm: vm)).toList()),
              ],
            ),
          ),
        PrimaryButton(label: tr('Tambah urusan'), icon: AppIcons.plus, height: 52, onPressed: () => showAddTaskSheet(context, vm)),
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
    return PastelHero(
      tone: PastelTone.rose,
      object: 'brain',
      objectSize: 112,
      label: tr('Yang dipikirin diam-diam'),
      head: Text(
        tr('{0} ingat {1} hal kecil minggu ini', [vm.partnerName, items.length]),
        style: AppText.display(22, letterSpacing: -0.5, height: 1.15),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          for (final t in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(14)),
              child: Row(spacing: 8, children: [
                IconBox(icon: iconFor(t.icon), size: 28, color: AppColors.rose, background: Colors.transparent),
                Expanded(child: Text(t.title, style: AppText.body(13, weight: FontWeight.w600))),
              ]),
            ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              await vm.sendThanks(tr('Makasih udah ingat {0}', [items.first.title.toLowerCase()]));
              if (context.mounted) showSnack(context, tr('Ucapan makasih terkirim ke {0}.', [vm.partnerName]));
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0x40B9536B))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 8, children: [
                const Object3D('red_heart', size: 18),
                Text(tr('Bilang makasih ke {0}', [vm.partnerName]), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.rose)),
              ]),
            ),
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
    final open = !task.together && task.doerUid == null;
    Widget? doer;
    if (task.together) {
      doer = _role(AppIcons.users, tr('Berdua'), AppColors.muted, AppColors.fieldFill);
    } else if (!open) {
      final who = vm.isMe(task.doerUid) ? tr('Kamu kerjakan') : tr('{0} kerjakan', [vm.firstNameOf(task.doerName)]);
      doer = _role(AppIcons.hand, who, AppColors.muted, AppColors.fieldFill);
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Opacity(opacity: task.isDone ? 0.5 : 1, child: IconBox(icon: iconFor(task.icon), size: 42, color: AppColors.muted, background: AppColors.fieldFill)),
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
                    _role(AppIcons.lightbulb, thinker, AppColors.muted, AppColors.fieldFill),
                    ?doer,
                    if (task.time != null) _role(AppIcons.clock, task.time!, AppColors.muted, AppColors.fieldFill),
                  ]),
                ],
              ),
            ),
            if (open && !task.isDone)
              GestureDetector(
                onTap: () => vm.takeOver(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.jadeSoft, borderRadius: BorderRadius.circular(16)),
                  child: Text(tr('Aku ambil'), style: AppText.body(12, weight: FontWeight.w700, color: AppColors.jade)),
                ),
              )
            else
              CheckCircle(checked: task.isDone, size: 26, onTap: () => vm.toggle(task)),
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
