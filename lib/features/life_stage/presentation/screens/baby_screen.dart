import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/life_stage_entity.dart';
import '../viewmodels/life_stage_viewmodel.dart';
import '../widgets/life_stage_scope.dart';
import '../widgets/plan_editors.dart';

/// Menyambut bayi: usia kandungan, anggaran, tas persalinan, dan urusan bayi berdua.
class BabyScreen extends StatelessWidget {
  const BabyScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeStageScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LifeStageViewModel>();
    final b = vm.baby;
    if (b == null) {
      return AppScaffold(
        tab: AppTab.kita,
        children: [
          AppNavBar(title: tr('Menyambut bayi')),
          PastelHero(
            tone: PastelTone.sky,
            object: 'baby_bottle',
            label: tr('Menyambut bayi'),
            plus: true,
            head: Text(tr('Siap menyambut si kecil, berdua.'), style: AppText.display(24, height: 1.15)),
            body: Text(tr('Anggaran persalinan, tas persalinan, dan pembagian urusan bayi baru.'), style: AppText.body(14, color: AppColors.muted, height: 1.4)),
          ),
          PrimaryButton(label: tr('Mulai rencana'), icon: AppIcons.baby, onPressed: () => _setup(context, vm)),
        ],
      );
    }

    final now = DateTime.now();
    final week = b.weekOf(now);
    final weeksLeft = (b.dueDate.difference(now).inDays / 7).ceil().clamp(0, 42);
    final trimester = week < 14 ? 1 : (week < 28 ? 2 : 3);
    const tones = [AppColors.amber, AppColors.jade, AppColors.rose, AppColors.sky, AppColors.lilac];

    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(
          title: tr('Menyambut bayi'),
          actionIcon: AppIcons.ellipsis,
          onAction: () => showPlanMenu(context, planName: tr('Menyambut bayi'), onEdit: () => _editPlan(context, vm, b), onDelete: vm.deleteBaby),
        ),
        PastelHero(
          tone: PastelTone.sky,
          object: 'baby_bottle',
          objectSize: 136,
          objectRotation: -16,
          label: tr('Perkiraan lahir, {0}', [formatFullDate(b.dueDate)]),
          plus: true,
          onTap: () => _editPlan(context, vm, b),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            HeroNumber('$week', size: 76),
            Text(tr('minggu. Trimester {0}, {1} minggu lagi ketemu si kecil.', [trimester, weeksLeft]), style: AppText.body(13, color: AppColors.muted, height: 1.4)),
          ]),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 2,
            children: [
              for (int i = 1; i <= 40; i++)
                Expanded(
                  child: Container(
                    height: i == week ? 14 : 8,
                    decoration: BoxDecoration(color: i <= week ? AppColors.sky : const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
        ),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
            Row(children: [
              Expanded(child: Text(tr('Anggaran menyambut bayi'), style: AppText.body(15, weight: FontWeight.w700))),
              GestureDetector(
                onTap: () async {
                  final line = await showBudgetLineEditor(context, nameHint: tr('Nama, misalnya Imunisasi'));
                  if (line != null && context.mounted) await saveOrWarn(context, vm.addBabyBudget(line));
                },
                child: Text(tr('+ Tambah'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.amber)),
              ),
            ]),
            if (b.budgets.isEmpty) Text(tr('Belum ada rincian anggaran. Tambah dengan + Tambah.'), style: AppText.body(13, color: AppColors.muted)),
            ...List.generate(b.budgets.length, (i) {
              final l = b.budgets[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _budgetActions(context, vm, i, l),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: [
                  Row(children: [
                    Expanded(child: Text(l.name, style: AppText.body(13, weight: FontWeight.w600))),
                    Text('${formatRupiahShort(l.used)} / ${formatRupiahShort(l.total)}', style: AppText.body(13, weight: FontWeight.w700, color: l.used > l.total ? AppColors.rose : AppColors.muted)),
                  ]),
                  ProgressBar(value: l.total <= 0 ? 0 : (l.used / l.total).clamp(0, 1), color: tones[i % tones.length]),
                ]),
              );
            }),
            if (b.budgets.isNotEmpty) ...[
              const Divider(color: AppColors.hairline, height: 4),
              Row(children: [
                Expanded(child: Text(tr('Total'), style: AppText.body(13, weight: FontWeight.w700))),
                Text('${formatRupiahShort(b.budgetUsed)} / ${formatRupiahShort(b.budgetTotal)}', style: AppText.body(13, weight: FontWeight.w700)),
              ]),
              Text(tr('Ketuk rincian untuk catat pemakaian, ubah angka, atau hapus.'), style: AppText.body(12, color: AppColors.faint)),
            ],
          ]),
        ),
        SectionHeader(
          title: tr('Urusan bayi berdua'),
          action: tr('+ Tambah'),
          actionColor: AppColors.amber,
          onAction: () async {
            final item = await showChecklistEditor(context, titleHint: tr('Misalnya: beli popok newborn'));
            if (item != null && context.mounted) await saveOrWarn(context, vm.addBabyTask(item));
          },
        ),
        ListCard(children: [
          if (b.tasks.isEmpty) EmptyNote(tr('Belum ada urusan. Tambah dengan + Tambah di atas.')),
          ...List.generate(
            b.tasks.length,
            (i) => ListRow(
              leading: CheckCircle(checked: b.tasks[i].done, onTap: () => vm.toggleBabyTask(i)),
              title: b.tasks[i].title,
              subtitle: b.tasks[i].note.isEmpty ? null : b.tasks[i].note,
              titleColor: b.tasks[i].done ? AppColors.faint : AppColors.ink,
              onTap: () => _taskActions(context, vm, i, b.tasks[i]),
            ),
          ),
          ListRow(
            icon: AppIcons.shoppingBag,
            iconColor: AppColors.amber,
            iconBackground: AppColors.amberSoft,
            title: tr('Tas persalinan'),
            subtitle: tr('{0} dari {1} barang siap', [b.bagReady, b.bagTotal]),
            onTap: () async {
              final total = await showPickerSheet<int>(
                context,
                title: tr('Jumlah barang di tas'),
                items: List.generate(40, (i) => i + 1),
                label: (c) => tr('{0} barang', [c]),
                selected: b.bagTotal,
              );
              if (total != null) await vm.setBagTotal(total);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(AppIcons.minus, size: 16), onPressed: () => vm.setBagReady(b.bagReady - 1)),
              IconButton(icon: const Icon(AppIcons.plus, size: 16), onPressed: () => vm.setBagReady(b.bagReady + 1)),
            ]),
          ),
        ]),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Text(tr('KENAPA INI PENTING'), style: AppText.eyebrow(const Color(0x99FFFFFF))),
            Text(
              tr('Setelah anak pertama lahir, waktu berdua biasanya berkurang drastis. Check-in 2 menit dan dek obrolan "Anak" disiapkan untuk masa ini.'),
              style: AppText.body(14, color: Colors.white, height: 1.4),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _budgetActions(BuildContext context, LifeStageViewModel vm, int i, BudgetLine l) async {
    final a = await showPlanActions(context, title: l.name, actions: const [PlanAction.use, PlanAction.edit, PlanAction.delete]);
    if (a == null || !context.mounted) return;
    switch (a) {
      case PlanAction.use:
        final v = await showAmountSheet(context, title: tr('Tambah pemakaian {0}', [l.name]), initial: 0, confirmLabel: tr('Catat'));
        if (v != null && context.mounted) await saveOrWarn(context, vm.addBabyBudgetUse(i, v));
      case PlanAction.edit:
        final line = await showBudgetLineEditor(context, initial: l);
        if (line != null && context.mounted) await saveOrWarn(context, vm.updateBabyBudget(i, line));
      case PlanAction.delete:
        if (await confirmPlanDelete(context, l.name) && context.mounted) await saveOrWarn(context, vm.deleteBabyBudget(i));
      default:
    }
  }

  Future<void> _taskActions(BuildContext context, LifeStageViewModel vm, int i, ChecklistItem t) async {
    final a = await showPlanActions(context, title: t.title, done: t.done, actions: const [PlanAction.toggle, PlanAction.edit, PlanAction.delete]);
    if (a == null || !context.mounted) return;
    switch (a) {
      case PlanAction.toggle:
        await vm.toggleBabyTask(i);
      case PlanAction.edit:
        final item = await showChecklistEditor(context, initial: t);
        if (item != null && context.mounted) await saveOrWarn(context, vm.updateBabyTask(i, item));
      case PlanAction.delete:
        if (await confirmPlanDelete(context, t.title) && context.mounted) await saveOrWarn(context, vm.deleteBabyTask(i));
      default:
    }
  }

  /// Form mulai: perkiraan lahir dan anggaran. Angka awal hanya contoh, bisa diubah atau dikosongkan.
  Future<void> _setup(BuildContext context, LifeStageViewModel vm) async {
    var due = DateTime.now().add(const Duration(days: 120));
    final controllers = [for (final s in LifeStageViewModel.babyBudgetSuggestions) TextEditingController(text: s.$2.round().toString())];
    await showAppSheet<void>(
      context,
      title: tr('Rencana menyambut bayi'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          DateField(
            label: tr('Perkiraan lahir (HPL)'),
            date: due,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 300)),
            onChanged: (d) => setState(() => due = d),
          ),
          for (int i = 0; i < controllers.length; i++) MoneyField(controller: controllers[i], label: tr(LifeStageViewModel.babyBudgetSuggestions[i].$1)),
          InfoBanner(
            icon: AppIcons.info,
            text: tr('Angka awal ini contoh kasar (persalinan normal di RS swasta, perlengkapan dasar, biaya 3 bulan pertama). Ganti sesuai rencana kalian, kosongkan yang tidak perlu.'),
          ),
          PrimaryButton(
            label: tr('Mulai'),
            height: 52,
            onPressed: () async {
              final budgets = [
                for (int i = 0; i < controllers.length; i++)
                  if (parseRupiah(controllers[i].text) > 0) BudgetLine(name: tr(LifeStageViewModel.babyBudgetSuggestions[i].$1), total: parseRupiah(controllers[i].text)),
              ];
              final ok = await saveOrWarn(sheetContext, vm.startBaby(due, budgets));
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _editPlan(BuildContext context, LifeStageViewModel vm, BabyPlanEntity b) async {
    var due = b.dueDate;
    await showAppSheet<void>(
      context,
      title: tr('Ubah rencana'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          DateField(label: tr('Perkiraan lahir (HPL)'), date: due, lastDate: DateTime.now().add(const Duration(days: 300)), onChanged: (d) => setState(() => due = d)),
          Text(tr('Anggaran dan urusan diubah langsung dengan mengetuk barisnya.'), style: AppText.body(12, color: AppColors.muted)),
          PrimaryButton(
            label: tr('Simpan'),
            height: 52,
            onPressed: () async {
              final ok = await saveOrWarn(sheetContext, vm.updateDueDate(due));
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }
}
