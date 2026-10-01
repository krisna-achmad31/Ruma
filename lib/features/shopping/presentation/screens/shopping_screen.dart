import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/shopping_item_entity.dart';
import '../viewmodels/shopping_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<ShoppingViewModel>(
      create: (user) => ShoppingViewModel(
        shoppingRepository: buildShoppingRepository(),
        financeRepository: buildFinanceRepository(),
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _controller = TextEditingController();
  String _place = tr('Pasar');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add(ShoppingViewModel vm) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await vm.addFromText(text, _place);
    _controller.clear();
  }

  void _share(ShoppingViewModel vm) {
    final lines = vm.byPlace.entries.map((e) => tr('{0}:\n{1}', [e.key, e.value.map((i) => '${i.isChecked ? '[x]' : '[ ]'} ${i.name}').join('\n')])).join('\n\n');
    SharePlus.instance.share(ShareParams(text: tr('Daftar belanja\n\n{0}', [lines])));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final groups = vm.byPlace;
    final checked = vm.checked;
    final places = {tr('Pasar'), tr('Minimarket'), ...groups.keys}.toList();

    return AppScaffold(
      tab: AppTab.urusan,
      children: [
        AppNavBar(title: tr('Belanja'), actionIcon: AppIcons.share2, onAction: () => _share(vm)),
        GlassCard(
          strong: true,
          radius: 26,
          padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
          child: Row(spacing: 10, children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppText.body(14),
                onSubmitted: (_) => _add(vm),
                decoration: InputDecoration(border: InputBorder.none, hintText: tr('Tambah barang, mis. “telur 1 kg 28rb”'), hintStyle: AppText.body(14, color: AppColors.faint)),
              ),
            ),
            GestureDetector(
              onTap: () => _add(vm),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(AppIcons.plus, size: 18, color: Colors.white),
              ),
            ),
          ]),
        ),
        Wrap(
          spacing: 8,
          children: places
              .map((p) => ChoiceChip(label: Text(p), selected: _place == p, onSelected: (_) => setState(() => _place = p), selectedColor: AppColors.jadeSoft))
              .toList(),
        ),
        if (groups.isEmpty) GlassCard(child: EmptyNote(tr('Daftar belanja kosong. Tambah barang di atas.'), icon: AppIcons.shoppingCart)),
        ...groups.entries.map((g) => LabeledGroup(label: g.key, rows: g.value.map((i) => _ItemRow(item: i, vm: vm)).toList())),
        if (checked.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)),
            child: Row(spacing: 12, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr('{0} dicentang · {1}', [checked.length, formatRupiah(vm.checkedTotal)]), style: AppText.body(15, weight: FontWeight.w700, color: Colors.white)),
                  Text(tr('Catat ke amplop {0}', [vm.groceryCategory?.name ?? 'belanja']), style: AppText.body(12, color: const Color(0xB3FFFFFF))),
                ]),
              ),
              GestureDetector(
                onTap: () async {
                  final ok = await vm.recordChecked();
                  if (context.mounted) showSnack(context, ok ? tr('Belanja tercatat di Uang.') : tr('Tambah dompet dulu di Uang.'));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Text(tr('Catat'), style: AppText.body(13, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ShoppingItemEntity item;
  final ShoppingViewModel vm;

  const _ItemRow({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final mine = item.addedByUid == vm.uid;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 12), child: const Icon(AppIcons.trash2, color: AppColors.rose, size: 18)),
      onDismissed: (_) => vm.delete(item),
      child: InkWell(
        onTap: () => vm.toggle(item),
        onLongPress: () async {
          final v = await showAmountSheet(context, title: tr('Harga {0}', [item.name]), initial: item.lastPrice > 0 ? item.lastPrice : 10000);
          if (v != null) await vm.setPrice(item, v);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(spacing: 12, children: [
            CheckCircle(checked: item.isChecked),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                Text(
                  item.name,
                  style: AppText.body(15,
                      weight: FontWeight.w600,
                      color: item.isChecked ? AppColors.faint : AppColors.ink,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null),
                ),
                Text(item.lastPrice > 0 ? tr('terakhir {0}', [formatRupiahShort(item.lastPrice)]) : tr('tekan lama untuk isi harga'), style: AppText.body(12, color: AppColors.muted)),
              ]),
            ),
            Avatar(name: item.addedByName, color: mine ? AppColors.jade : AppColors.rose, size: 24),
          ]),
        ),
      ),
    );
  }
}
