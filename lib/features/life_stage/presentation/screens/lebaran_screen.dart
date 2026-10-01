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

/// Lebaran dan THR: alokasi THR, daftar salam tempel, dan checklist mudik.
class LebaranScreen extends StatelessWidget {
  const LebaranScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeStageScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  static const _tones = [AppColors.jade, AppColors.sky, AppColors.rose, AppColors.amber, AppColors.lilac, AppColors.butter];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LifeStageViewModel>();
    final l = vm.lebaran;
    if (l == null) {
      return AppScaffold(
        tab: AppTab.uang,
        children: [
          AppNavBar(title: tr('Lebaran & THR')),
          PastelHero(
            tone: PastelTone.butter,
            object: 'crescent_moon',
            label: tr('Lebaran & THR'),
            plus: true,
            head: Text(tr('THR aman sampai habis Lebaran.'), style: AppText.display(24, height: 1.15)),
            body: Text(tr('Rencanakan alokasi THR, salam tempel, dan mudik dari sekarang.'), style: AppText.body(14, color: AppColors.muted, height: 1.4)),
          ),
          PrimaryButton(label: tr('Mulai rencana Lebaran'), icon: AppIcons.moonStar, onPressed: () => _setup(context, vm)),
        ],
      );
    }

    final days = vm.daysUntil(l.eidDate);
    final allocTotal = l.allocatedTotal;
    final unallocated = l.thrAmount - allocTotal;
    return AppScaffold(
      tab: AppTab.uang,
      children: [
        AppNavBar(
          title: tr('Lebaran & THR'),
          actionIcon: AppIcons.ellipsis,
          onAction: () => showPlanMenu(context, planName: tr('Rencana Lebaran'), onEdit: () => _setup(context, vm, initial: l), onDelete: vm.deleteLebaran),
        ),
        PastelHero(
          tone: PastelTone.butter,
          object: 'crescent_moon',
          objectSize: 136,
          label: tr('Idulfitri, sekitar {0} {1} {2}', [l.eidDate.day, monthNamesId[l.eidDate.month - 1], l.eidDate.year]),
          plus: true,
          onTap: () => _setup(context, vm, initial: l),
          head: days > 0
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
                  HeroNumber('$days', size: 76),
                  Text(
                    tr('hari lagi. Sisihkan {0} per bulan mulai sekarang, biar THR nggak habis sebelum mudik.', [formatRupiahShort(vm.lebaranMonthlySetAside(l))]),
                    style: AppText.body(13, color: AppColors.muted, height: 1.4),
                  ),
                ])
              : Text(tr('Selamat Lebaran'), style: AppText.display(30, height: 1.1)),
        ),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr('Rencana THR'), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
                  Text(formatRupiah(l.thrAmount), style: AppText.display(24, letterSpacing: -0.6)),
                ]),
              ),
              GestureDetector(
                onTap: () async {
                  final line = await showBudgetLineEditor(context, withUsed: false, nameHint: tr('Nama, misalnya Hampers kantor'));
                  if (line != null && context.mounted) await saveOrWarn(context, vm.addAllocation(line));
                },
                child: Text(tr('+ Tambah'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
              ),
            ]),
            if (l.allocations.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    spacing: 3,
                    children: List.generate(l.allocations.length, (i) {
                      final flex = allocTotal <= 0 ? 1 : (l.allocations[i].total / allocTotal * 1000).round().clamp(1, 1000);
                      return Expanded(flex: flex, child: Container(color: _tones[i % _tones.length]));
                    }),
                  ),
                ),
              ),
            if (l.allocations.isEmpty) Text(tr('Belum ada alokasi. Tambah sendiri atau bagi otomatis.'), style: AppText.body(13, color: AppColors.muted)),
            ...List.generate(l.allocations.length, (i) {
              final a = l.allocations[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _allocationActions(context, vm, i, a),
                child: Row(spacing: 10, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _tones[i % _tones.length], shape: BoxShape.circle)),
                  Expanded(child: Text(a.name, style: AppText.body(14, weight: FontWeight.w600))),
                  Text(formatRupiahShort(a.total), style: AppText.body(14, weight: FontWeight.w700)),
                ]),
              );
            }),
            if (unallocated.abs() >= 1000)
              Text(
                unallocated > 0 ? tr('Belum dialokasikan {0}', [formatRupiahShort(unallocated)]) : tr('Alokasi lebih {0} dari THR', [formatRupiahShort(-unallocated)]),
                style: AppText.body(12, weight: FontWeight.w600, color: unallocated > 0 ? AppColors.muted : AppColors.rose),
              ),
            if (l.recipientsTotal > 0)
              Text(tr('Daftar salam tempel di bawah totalnya {0}.', [formatRupiahShort(l.recipientsTotal)]), style: AppText.body(12, color: AppColors.faint)),
            GestureDetector(
              onTap: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: tr('Bagi ulang otomatis?'),
                  message: tr('THR dibagi lagi dengan usulan: zakat 9%, mudik 26%, salam tempel 10%, baju & kue 15%, tabungan 40%. Alokasi sekarang ditimpa.'),
                  confirmLabel: tr('Bagi ulang'),
                );
                if (ok && context.mounted) await saveOrWarn(context, vm.resplitThr());
              },
              child: Text(tr('Bagi ulang otomatis'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
            ),
          ]),
        ),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
            Row(children: [
              Expanded(child: Text(tr('Daftar salam tempel'), style: AppText.body(15, weight: FontWeight.w700))),
              GestureDetector(onTap: () => _recipient(context, vm), child: Text(tr('+ Tambah'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade))),
            ]),
            if (l.recipients.isEmpty) Text(tr('Belum ada penerima.'), style: AppText.body(13, color: AppColors.muted)),
            ...List.generate(l.recipients.length, (i) {
              final r = l.recipients[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _recipientActions(context, vm, i, r),
                child: Row(spacing: 8, children: [
                  Expanded(child: Text(r.group, style: AppText.body(13))),
                  Text(tr('{0} orang', [r.count]), style: AppText.body(12, color: AppColors.muted)),
                  Text(formatRupiahShort(r.amount), style: AppText.body(13, weight: FontWeight.w700)),
                ]),
              );
            }),
            const Divider(color: AppColors.hairline),
            Row(children: [
              Expanded(child: Text(tr('Total'), style: AppText.body(13, weight: FontWeight.w700))),
              Text(formatRupiah(l.recipientsTotal), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
            ]),
          ]),
        ),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
            Row(children: [
              Expanded(child: Text(tr('Checklist mudik'), style: AppText.body(15, weight: FontWeight.w700))),
              GestureDetector(
                onTap: () async {
                  final item = await showChecklistEditor(context, titleHint: tr('Misalnya: beli oleh-oleh'));
                  if (item != null && context.mounted) await saveOrWarn(context, vm.addLebaranItem(item));
                },
                child: Text(tr('+ Tambah'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
              ),
            ]),
            if (l.checklist.isEmpty) Text(tr('Belum ada checklist.'), style: AppText.body(13, color: AppColors.muted)),
            ...List.generate(
              l.checklist.length,
              (i) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _checklistActions(context, vm, i, l.checklist[i]),
                child: Row(spacing: 10, children: [
                  CheckCircle(checked: l.checklist[i].done, size: 22, onTap: () => vm.toggleLebaranItem(i)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                      Text(l.checklist[i].title, style: AppText.body(14, weight: FontWeight.w600, color: l.checklist[i].done ? AppColors.faint : AppColors.ink)),
                      if (l.checklist[i].note.isNotEmpty) Text(l.checklist[i].note, style: AppText.body(12, color: AppColors.muted)),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _allocationActions(BuildContext context, LifeStageViewModel vm, int i, BudgetLine a) async {
    final action = await showPlanActions(context, title: a.name, actions: const [PlanAction.edit, PlanAction.delete]);
    if (action == null || !context.mounted) return;
    if (action == PlanAction.edit) {
      final line = await showBudgetLineEditor(context, initial: a, withUsed: false);
      if (line != null && context.mounted) await saveOrWarn(context, vm.updateAllocation(i, line));
    } else if (await confirmPlanDelete(context, a.name) && context.mounted) {
      await saveOrWarn(context, vm.deleteAllocation(i));
    }
  }

  Future<void> _recipientActions(BuildContext context, LifeStageViewModel vm, int i, RecipientGroup r) async {
    final action = await showPlanActions(context, title: r.group, actions: const [PlanAction.edit, PlanAction.delete]);
    if (action == null || !context.mounted) return;
    if (action == PlanAction.edit) {
      await _recipient(context, vm, index: i, initial: r);
    } else if (await confirmPlanDelete(context, r.group) && context.mounted) {
      await saveOrWarn(context, vm.deleteRecipient(i));
    }
  }

  Future<void> _checklistActions(BuildContext context, LifeStageViewModel vm, int i, ChecklistItem t) async {
    final action = await showPlanActions(context, title: t.title, done: t.done, actions: const [PlanAction.toggle, PlanAction.edit, PlanAction.delete]);
    if (action == null || !context.mounted) return;
    switch (action) {
      case PlanAction.toggle:
        await vm.toggleLebaranItem(i);
      case PlanAction.edit:
        final item = await showChecklistEditor(context, initial: t);
        if (item != null && context.mounted) await saveOrWarn(context, vm.updateLebaranItem(i, item));
      case PlanAction.delete:
        if (await confirmPlanDelete(context, t.title) && context.mounted) await saveOrWarn(context, vm.deleteLebaranItem(i));
      default:
    }
  }

  /// Form mulai atau ubah rencana: perkiraan Idulfitri dan THR berdua.
  Future<void> _setup(BuildContext context, LifeStageViewModel vm, {LebaranPlanEntity? initial}) async {
    var eid = initial?.eidDate ?? DateTime(2027, 3, 10);
    final thr = TextEditingController(text: (initial?.thrAmount ?? 0) > 0 ? initial!.thrAmount.round().toString() : '');
    await showAppSheet<void>(
      context,
      title: initial == null ? tr('Rencana Lebaran') : tr('Ubah rencana'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          DateField(label: tr('Perkiraan Idulfitri'), date: eid, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime(2030), onChanged: (d) => setState(() => eid = d)),
          MoneyField(
            controller: thr,
            label: tr('Perkiraan THR berdua'),
            helper: initial == null ? tr('Nanti dibagi otomatis ke zakat, mudik, salam tempel, baju & kue, dan tabungan. Semua bisa diubah.') : tr('Mengubah THR tidak mengubah alokasi. Pakai Bagi ulang otomatis kalau perlu.'),
          ),
          PrimaryButton(
            label: initial == null ? tr('Buat rencana') : tr('Simpan'),
            height: 52,
            onPressed: () async {
              final amount = parseRupiah(thr.text);
              if (amount <= 0) {
                showSnack(context, tr('Isi perkiraan THR dulu.'));
                return;
              }
              final ok = await saveOrWarn(sheetContext, initial == null ? vm.startLebaran(eidDate: eid, thr: amount) : vm.updateLebaranInfo(eidDate: eid, thr: amount));
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }

  /// Tambah atau ubah kelompok penerima salam tempel dalam satu form.
  Future<void> _recipient(BuildContext context, LifeStageViewModel vm, {int? index, RecipientGroup? initial}) async {
    final group = TextEditingController(text: initial?.group ?? '');
    final amount = TextEditingController(text: (initial?.amount ?? 50000).round().toString());
    var count = initial?.count ?? 1;
    await showAppSheet<void>(
      context,
      title: initial == null ? tr('Penerima baru') : tr('Ubah penerima'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          AppTextField(controller: group, hint: tr('Misalnya: Sepupu kecil'), autofocus: initial == null),
          Row(children: [
            Expanded(child: Text(tr('Jumlah orang'), style: AppText.body(14, weight: FontWeight.w600))),
            IconButton(icon: const Icon(AppIcons.minus, size: 18), onPressed: count > 1 ? () => setState(() => count--) : null),
            Text('$count', style: AppText.display(20)),
            IconButton(icon: const Icon(AppIcons.plus, size: 18), onPressed: () => setState(() => count++)),
          ]),
          MoneyField(controller: amount, label: tr('Per orang')),
          PrimaryButton(
            label: tr('Simpan'),
            height: 52,
            onPressed: () async {
              final a = parseRupiah(amount.text);
              if (group.text.trim().isEmpty || a <= 0) {
                showSnack(context, tr('Isi nama kelompok dan nominal per orang dulu.'));
                return;
              }
              final r = RecipientGroup(group: group.text.trim(), count: count, amount: a);
              final ok = await saveOrWarn(sheetContext, index == null ? vm.addRecipient(r.group, r.count, r.amount) : vm.updateRecipient(index, r));
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }
}
