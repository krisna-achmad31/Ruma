import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/life_stage_entity.dart';

/// Aksi yang muncul saat baris rencana diketuk.
enum PlanAction { toggle, advance, use, edit, delete }

double parseRupiah(String text) => double.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;

String _amountText(double v) => v > 0 ? v.round().toString() : '';

/// Menu aksi untuk satu baris: tandai, catat pemakaian, ubah, hapus.
Future<PlanAction?> showPlanActions(BuildContext context, {required String title, required List<PlanAction> actions, bool done = false, String? advanceLabel}) {
  String label(PlanAction a) => switch (a) {
        PlanAction.toggle => done ? tr('Batal tandai beres') : tr('Tandai beres'),
        PlanAction.advance => advanceLabel ?? tr('Tandai sudah dibayar'),
        PlanAction.use => tr('Catat pemakaian'),
        PlanAction.edit => tr('Ubah'),
        PlanAction.delete => tr('Hapus'),
      };
  IconData icon(PlanAction a) => switch (a) {
        PlanAction.toggle => AppIcons.circleCheck,
        PlanAction.advance => AppIcons.check,
        PlanAction.use => AppIcons.plus,
        PlanAction.edit => AppIcons.pencil,
        PlanAction.delete => AppIcons.trash2,
      };
  return showPickerSheet<PlanAction>(context, title: title, items: actions, label: label, icon: icon);
}

/// Konfirmasi hapus dengan nama barisnya.
Future<bool> confirmPlanDelete(BuildContext context, String name) => showConfirmDialog(
      context,
      title: tr('Hapus "{0}"?', [name]),
      message: tr('Yang sudah dihapus tidak bisa dikembalikan.'),
      confirmLabel: tr('Hapus'),
      icon: AppIcons.trash2,
      destructive: true,
    );

/// Form tugas atau checklist: judul dan catatan.
Future<ChecklistItem?> showChecklistEditor(BuildContext context, {ChecklistItem? initial, String? titleHint}) {
  final title = TextEditingController(text: initial?.title ?? '');
  final note = TextEditingController(text: initial?.note ?? '');
  return showAppSheet<ChecklistItem>(
    context,
    title: initial == null ? tr('Tambah tugas') : tr('Ubah tugas'),
    builder: (sheetContext) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
      AppTextField(controller: title, hint: titleHint ?? tr('Misalnya: beli popok newborn'), autofocus: true),
      AppTextField(controller: note, hint: tr('Catatan (opsional)')),
      PrimaryButton(
        label: tr('Simpan'),
        height: 52,
        onPressed: () {
          final t = title.text.trim();
          if (t.isEmpty) return;
          Navigator.of(sheetContext).pop((initial ?? const ChecklistItem(title: '')).copyWith(title: t, note: note.text.trim()));
        },
      ),
    ]),
  );
}

/// Form satu baris anggaran: nama, total, dan (opsional) yang sudah terpakai.
Future<BudgetLine?> showBudgetLineEditor(BuildContext context, {BudgetLine? initial, bool withUsed = true, String? nameHint}) {
  final name = TextEditingController(text: initial?.name ?? '');
  final total = TextEditingController(text: _amountText(initial?.total ?? 0));
  final used = TextEditingController(text: _amountText(initial?.used ?? 0));
  return showAppSheet<BudgetLine>(
    context,
    title: initial == null ? tr('Rincian baru') : tr('Ubah rincian'),
    builder: (sheetContext) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
      AppTextField(controller: name, hint: nameHint ?? tr('Nama, misalnya Imunisasi'), autofocus: initial == null),
      MoneyField(controller: total, label: tr('Anggaran')),
      if (withUsed) MoneyField(controller: used, label: tr('Sudah terpakai')),
      PrimaryButton(
        label: tr('Simpan'),
        height: 52,
        onPressed: () {
          final n = name.text.trim();
          final t = parseRupiah(total.text);
          if (n.isEmpty || t <= 0) return;
          Navigator.of(sheetContext).pop(BudgetLine(name: n, total: t, used: withUsed ? parseRupiah(used.text) : (initial?.used ?? 0)));
        },
      ),
    ]),
  );
}

/// Isian rupiah berlabel, hanya angka.
class MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;

  const MoneyField({super.key, required this.controller, required this.label, this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
      Text(label, style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppText.body(16, weight: FontWeight.w700),
          decoration: InputDecoration(border: InputBorder.none, prefixText: 'Rp ', hintText: '0', hintStyle: AppText.body(16, color: AppColors.faint)),
        ),
      ),
      if (helper != null) Text(helper!, style: AppText.body(12, color: AppColors.faint)),
    ]);
  }
}

/// Baris tanggal yang bisa diketuk untuk memilih tanggal.
class DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateField({super.key, required this.label, required this.date, required this.onChanged, this.firstDate, this.lastDate});

  @override
  Widget build(BuildContext context) {
    return ListRow(
      icon: AppIcons.calendar,
      title: formatLongDate(date),
      subtitle: label,
      chevron: true,
      onTap: () async {
        final first = firstDate ?? DateTime.now().subtract(const Duration(days: 365));
        final p = await showDatePicker(
          context: context,
          initialDate: date.isBefore(first) ? first : date,
          firstDate: first,
          lastDate: lastDate ?? DateTime(2035),
        );
        if (p != null) onChanged(p);
      },
    );
  }
}

/// Menu rencana di pojok kanan atas: ubah atau hapus rencana.
Future<void> showPlanMenu(BuildContext context, {required String planName, required VoidCallback onEdit, required Future<void> Function() onDelete}) async {
  final action = await showPickerSheet<PlanAction>(
    context,
    title: planName,
    items: const [PlanAction.edit, PlanAction.delete],
    label: (a) => a == PlanAction.edit ? tr('Ubah rencana') : tr('Hapus rencana'),
    sublabel: (a) => a == PlanAction.edit ? tr('Tanggal dan angka utama') : tr('Semua isian rencana ini ikut terhapus'),
    icon: (a) => a == PlanAction.edit ? AppIcons.pencil : AppIcons.trash2,
  );
  if (!context.mounted || action == null) return;
  if (action == PlanAction.edit) {
    onEdit();
    return;
  }
  final ok = await showConfirmDialog(
    context,
    title: tr('Hapus rencana {0}?', [planName.toLowerCase()]),
    message: tr('Anggaran, tugas, dan catatan di rencana ini dihapus untuk kalian berdua. Tidak bisa dikembalikan.'),
    confirmLabel: tr('Hapus rencana'),
    icon: AppIcons.trash2,
    destructive: true,
  );
  if (ok && context.mounted) await saveOrWarn(context, onDelete());
}
