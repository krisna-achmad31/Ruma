import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/life_stage_entity.dart';
import '../viewmodels/life_stage_viewmodel.dart';
import '../widgets/life_stage_scope.dart';
import '../widgets/plan_editors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Siap nikah: anggaran nikah, jadwal bayar vendor, persiapan, dan obrolan pranikah.
class WeddingScreen extends StatelessWidget {
  const WeddingScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeStageScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LifeStageViewModel>();
    final w = vm.wedding;
    if (w == null) {
      return AppScaffold(
        tab: AppTab.kita,
        children: [
          AppNavBar(title: tr('Siap nikah')),
          HeroCard(
            colors: AppColors.roseGradient,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
              const PlusBadge(onDark: true),
              Text(tr('Persiapan nikah, dipikul berdua dari awal.'), style: AppText.display(26, color: Colors.white, height: 1.15)),
              Text(tr('Anggaran, jadwal bayar vendor, dan obrolan penting sebelum tinggal serumah.'), style: AppText.body(14, color: const Color(0xCCFFFFFF), height: 1.4)),
            ]),
          ),
          PrimaryButton(label: tr('Mulai rencana'), icon: AppIcons.gem, onPressed: () => _setup(context, vm)),
        ],
      );
    }

    final days = vm.daysUntil(w.weddingDate);
    final done = w.prepDone;
    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(
          title: tr('Siap nikah'),
          actionIcon: AppIcons.ellipsis,
          onAction: () => showPlanMenu(context, planName: tr('Rencana nikah'), onEdit: () => _setup(context, vm, initial: w), onDelete: vm.deleteWedding),
        ),
        HeroCard(
          colors: AppColors.roseGradient,
          onTap: () => _setup(context, vm, initial: w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
            Row(children: [
              Expanded(child: Text(tr('Akad & resepsi · {0}', [formatFullDate(w.weddingDate)]), style: AppText.body(13, weight: FontWeight.w600, color: const Color(0xCCFFFFFF)))),
              const PlusBadge(onDark: true),
            ]),
            Text(days > 0 ? tr('{0} hari lagi', [days]) : (days == 0 ? tr('Hari ini!') : tr('Selamat menempuh hidup baru')), style: AppText.display(36, color: Colors.white, letterSpacing: -1.1)),
            Text(tr('{0} · {1} dari {2} persiapan beres', [w.coupleNames, done, w.prep.length]), style: AppText.body(13, color: const Color(0xCCFFFFFF))),
            ProgressBar(value: w.prep.isEmpty ? 0 : done / w.prep.length, color: Colors.white, track: const Color(0x2EFFFFFF), height: 8),
          ]),
        ),
        GlassCard(
          onTap: () => _setup(context, vm, initial: w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr('Anggaran nikah'), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
                  Text(tr('{0} terpakai', [formatRupiahShort(w.committed)]), style: AppText.display(24, letterSpacing: -0.6)),
                ]),
              ),
              Text(tr('dari {0}', [formatRupiahShort(w.budgetTotal)]), style: AppText.body(13, color: AppColors.muted)),
            ]),
            ProgressBar(value: w.budgetTotal <= 0 ? 0 : w.committed / w.budgetTotal, color: AppColors.rose, height: 8),
            Row(spacing: 8, children: [
              for (final s in [(tr('Tabungan kalian'), w.savings, false), (tr('Bantuan keluarga'), w.familyHelp, false), (tr('Masih kurang'), w.shortfall, true)])
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                      Text(s.$1, style: AppText.body(11, color: AppColors.muted)),
                      Text(formatRupiahShort(s.$2), style: AppText.body(14, weight: FontWeight.w700, color: s.$3 && s.$2 > 0 ? AppColors.amber : AppColors.ink)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        SectionHeader(title: tr('Bayar vendor'), action: tr('+ Vendor'), actionColor: AppColors.rose, onAction: () => _addVendor(context, vm)),
        ListCard(
          children: w.vendors.isEmpty
              ? [EmptyNote(tr('Belum ada vendor. Tambah katering, foto, atau busana.'))]
              : w.vendors.map((v) {
                  final pill = switch (v.status) {
                    'lunas' => Pill(tr('Beres')),
                    'termin' => Pill(tr('Termin'), color: AppColors.amber, background: AppColors.amberSoft),
                    _ => const Pill('DP', color: AppColors.amber, background: AppColors.amberSoft),
                  };
                  return ListRow(
                    icon: AppIcons.store,
                    iconColor: AppColors.rose,
                    iconBackground: AppColors.roseSoft,
                    title: v.name,
                    subtitle: '${formatRupiahShort(v.amount)}${v.dueDate == null ? '' : ' · ${formatShortDate(v.dueDate!)}'}',
                    trailing: pill,
                    onTap: () => _vendorActions(context, vm, v),
                  );
                }).toList(),
        ),
        SectionHeader(
          title: tr('Persiapan'),
          action: tr('+ Tambah'),
          actionColor: AppColors.rose,
          onAction: () async {
            final item = await showChecklistEditor(context, titleHint: tr('Misalnya: fitting baju akad'));
            if (item != null && context.mounted) await saveOrWarn(context, vm.addPrep(item));
          },
        ),
        ListCard(children: [
          if (w.prep.isEmpty) EmptyNote(tr('Belum ada persiapan. Tambah dengan + Tambah di atas.')),
          ...List.generate(
            w.prep.length,
            (i) => ListRow(
              leading: CheckCircle(checked: w.prep[i].done, onTap: () => vm.togglePrep(i)),
              title: w.prep[i].title,
              subtitle: w.prep[i].note.isEmpty ? null : w.prep[i].note,
              titleColor: w.prep[i].done ? AppColors.faint : AppColors.ink,
              onTap: () => _prepActions(context, vm, i, w.prep[i]),
            ),
          ),
        ]),
        GlassCard(
          onTap: () => context.push('/together/conversation-cards'),
          padding: const EdgeInsets.all(16),
          child: Row(spacing: 14, children: [
            const IconBox(icon: AppIcons.messagesSquare, color: AppColors.rose, background: AppColors.roseSoft, size: 44),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
                Text(tr('Obrolan sebelum menikah'), style: AppText.body(15, weight: FontWeight.w700)),
                Text(tr('Siapa ingat tagihan, siapa masak, uang digabung atau tidak. Sepakati sebelum tinggal serumah.'), style: AppText.body(12, color: AppColors.muted, height: 1.35)),
              ]),
            ),
            const Icon(AppIcons.chevronRight, size: 16, color: AppColors.faint),
          ]),
        ),
        InfoBanner(icon: AppIcons.sparkles, text: tr('Setelah menikah, semua data berlanjut ke Uang rumah, Urusan, dan Perjalanan kita.')),
      ],
    );
  }

  Future<void> _setup(BuildContext context, LifeStageViewModel vm, {WeddingPlanEntity? initial}) async {
    String amount(double? v) => (v ?? 0) > 0 ? v!.round().toString() : '';
    final names = TextEditingController(text: initial?.coupleNames ?? '');
    final budget = TextEditingController(text: amount(initial?.budgetTotal));
    final savings = TextEditingController(text: amount(initial?.savings));
    final help = TextEditingController(text: amount(initial?.familyHelp));
    var date = initial?.weddingDate ?? DateTime.now().add(const Duration(days: 180));
    double parse(TextEditingController c) => parseRupiah(c.text);
    await showAppSheet<void>(
      context,
      title: initial == null ? tr('Rencana nikah') : tr('Ubah rencana'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          AppTextField(controller: names, hint: tr('Nama kalian, misalnya Rara & Bima'), autofocus: initial == null),
          DateField(label: tr('Tanggal akad'), date: date, onChanged: (d) => setState(() => date = d)),
          MoneyField(controller: budget, label: tr('Total anggaran')),
          MoneyField(controller: savings, label: tr('Tabungan kalian')),
          MoneyField(controller: help, label: tr('Bantuan keluarga')),
          PrimaryButton(
            label: initial == null ? tr('Mulai') : tr('Simpan'),
            height: 52,
            onPressed: () async {
              if (names.text.trim().isEmpty || parse(budget) <= 0) {
                showSnack(context, tr('Isi nama dan total anggaran dulu.'));
                return;
              }
              final n = names.text.trim();
              final ok = await saveOrWarn(
                sheetContext,
                initial == null
                    ? vm.startWedding(date: date, names: n, budget: parse(budget), savings: parse(savings), familyHelp: parse(help))
                    : vm.updateWeddingInfo(date: date, names: n, budget: parse(budget), savings: parse(savings), familyHelp: parse(help)),
              );
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _vendorActions(BuildContext context, LifeStageViewModel vm, VendorEntity v) async {
    final a = await showPlanActions(
      context,
      title: v.name,
      actions: [if (v.status != 'lunas') PlanAction.advance, PlanAction.edit, PlanAction.delete],
      advanceLabel: v.status == 'dp' ? tr('Tandai sudah bayar termin') : tr('Tandai lunas'),
    );
    if (a == null || !context.mounted) return;
    switch (a) {
      case PlanAction.advance:
        await saveOrWarn(context, vm.advanceVendor(v));
      case PlanAction.edit:
        await _addVendor(context, vm, initial: v);
      case PlanAction.delete:
        if (await confirmPlanDelete(context, v.name) && context.mounted) await saveOrWarn(context, vm.deleteVendor(v.id));
      default:
    }
  }

  Future<void> _prepActions(BuildContext context, LifeStageViewModel vm, int i, ChecklistItem t) async {
    final a = await showPlanActions(context, title: t.title, done: t.done, actions: const [PlanAction.toggle, PlanAction.edit, PlanAction.delete]);
    if (a == null || !context.mounted) return;
    switch (a) {
      case PlanAction.toggle:
        await vm.togglePrep(i);
      case PlanAction.edit:
        final item = await showChecklistEditor(context, initial: t);
        if (item != null && context.mounted) await saveOrWarn(context, vm.updatePrep(i, item));
      case PlanAction.delete:
        if (await confirmPlanDelete(context, t.title) && context.mounted) await saveOrWarn(context, vm.deletePrep(i));
      default:
    }
  }

  Future<void> _addVendor(BuildContext context, LifeStageViewModel vm, {VendorEntity? initial}) async {
    final name = TextEditingController(text: initial?.name ?? '');
    final amount = TextEditingController(text: (initial?.amount ?? 0) > 0 ? initial!.amount.round().toString() : '');
    var status = initial?.status ?? 'dp';
    DateTime? due = initial?.dueDate;
    await showAppSheet<void>(
      context,
      title: initial == null ? tr('Vendor baru') : tr('Ubah vendor'),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          AppTextField(controller: name, hint: tr('Misalnya: Katering 300 porsi'), autofocus: initial == null),
          MoneyField(controller: amount, label: tr('Total biaya')),
          Wrap(
            spacing: 8,
            children: [('dp', tr('Baru DP')), ('termin', tr('Termin')), ('lunas', tr('Lunas'))]
                .map((s) => ChoiceChip(label: Text(s.$2), selected: status == s.$1, onSelected: (_) => setState(() => status = s.$1), selectedColor: AppColors.roseSoft))
                .toList(),
          ),
          ListRow(
            icon: AppIcons.calendar,
            title: due == null ? tr('Tanpa jatuh tempo') : formatLongDate(due!),
            subtitle: tr('Pembayaran berikutnya'),
            chevron: due == null,
            trailing: due == null ? null : IconButton(icon: const Icon(AppIcons.x, size: 18, color: AppColors.faint), onPressed: () => setState(() => due = null)),
            onTap: () async {
              final p = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2035));
              if (p != null) setState(() => due = p);
            },
          ),
          PrimaryButton(
            label: tr('Simpan'),
            height: 52,
            onPressed: () async {
              final a = parseRupiah(amount.text);
              if (name.text.trim().isEmpty || a <= 0) {
                showSnack(context, tr('Isi nama vendor dan total biaya dulu.'));
                return;
              }
              final ok = await saveOrWarn(
                sheetContext,
                initial == null
                    ? vm.addVendor(name: name.text.trim(), amount: a, status: status, due: due)
                    : vm.updateVendor(VendorEntity(id: initial.id, name: name.text.trim(), icon: initial.icon, amount: a, status: status, note: initial.note, dueDate: due)),
              );
              if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ]),
      ),
    );
  }
}

