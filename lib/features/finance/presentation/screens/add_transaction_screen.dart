import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _quick = TextEditingController();
  int _type = 0;
  WalletEntity? _wallet;
  CategoryEntity? _category;
  DateTime _date = DateTime.now();
  String? _parsedFrom;
  bool _saving = false;

  static const _frequent = [('Galon', 22000.0), ('Bensin', 50000.0), ('Pulsa', 100000.0)];

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _quick.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  void _applyQuick(FinanceViewModel vm) {
    final e = vm.parse(_quick.text);
    if (e == null) {
      showSnack(context, tr('Belum kebaca nominalnya. Contoh: "sayur 86rb gopay".'));
      return;
    }
    setState(() {
      _type = e.isIncome ? 1 : 0;
      _amount.text = e.amount.round().toString();
      _note.text = e.title;
      _wallet = vm.walletById(e.walletId ?? '') ?? _wallet;
      _category = vm.categoryById(e.categoryId) ?? _category;
      _parsedFrom = _quick.text;
      _quick.clear();
    });
  }

  Future<void> _save(FinanceViewModel vm) async {
    if (_type == 2) {
      context.pushReplacement('/finance/transfer');
      return;
    }
    final wallet = _wallet ?? vm.spendingWallets.firstOrNull;
    if (_value <= 0 || wallet == null) {
      showSnack(context, tr('Isi nominal dan pilih dompet dulu.'));
      return;
    }
    setState(() => _saving = true);
    await vm.addTransaction(
      title: _note.text.trim().isEmpty ? (_category?.name ?? (_type == 1 ? tr('Pemasukan') : tr('Pengeluaran'))) : _note.text.trim(),
      amount: _value,
      isIncome: _type == 1,
      walletId: wallet.id,
      categoryId: _category?.id,
      date: _date,
    );
    if (!mounted) return;
    showSnack(context, tr('Transaksi tercatat.'));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final wallet = _wallet ?? vm.spendingWallets.firstOrNull;

    return AppScaffold(
      bottom: PrimaryButton(label: _type == 2 ? tr('Lanjut ke pindah saldo') : tr('Simpan'), loading: _saving, onPressed: () => _save(vm)),
      children: [
        AppNavBar(title: tr('Catat'), leadingIcon: AppIcons.x),
        SegmentedControl(labels: [tr('Keluar|uang'), tr('Masuk|uang'), tr('Pindah')], selected: _type, onChanged: (i) => setState(() => _type = i)),
        Column(
          spacing: 6,
          children: [
            IntrinsicWidth(
              child: TextField(
                controller: _amount,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.display(48, letterSpacing: -1.6),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(border: InputBorder.none, hintText: '0', prefixText: 'Rp', hintStyle: AppText.display(48, color: AppColors.faint)),
              ),
            ),
            if (_parsedFrom != null)
              Pill(tr('Dari ketikan: “{0}”', [_parsedFrom]), icon: AppIcons.sparkles, color: AppColors.amber, background: AppColors.amberSoft),
          ],
        ),
        GlassCard(
          strong: true,
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          child: Row(spacing: 10, children: [
            const Icon(AppIcons.sparkles, size: 16, color: AppColors.amber),
            Expanded(
              child: TextField(
                controller: _quick,
                style: AppText.body(14),
                onSubmitted: (_) => _applyQuick(vm),
                decoration: InputDecoration(border: InputBorder.none, hintText: tr('atau ketik: sayur 86rb gopay'), hintStyle: AppText.body(14, color: AppColors.faint)),
              ),
            ),
            IconButton(icon: const Icon(AppIcons.arrowUp, size: 18), onPressed: () => _applyQuick(vm)),
          ]),
        ),
        ListCard(children: [
          if (_type == 0)
            ListRow(
              icon: _category == null ? AppIcons.mails : iconFor(_category!.icon),
              title: _category?.name ?? tr('Pilih amplop'),
              subtitle: _category == null ? tr('Amplop') : tr('Amplop · sisa {0}', [formatRupiahShort(vm.remainingOf(_category!))]),
              chevron: true,
              onTap: () async {
                final c = await showPickerSheet(
                  context,
                  title: tr('Pilih amplop'),
                  items: vm.categories,
                  label: (c) => c.name,
                  sublabel: (c) => tr('Sisa {0}', [formatRupiah(vm.remainingOf(c))]),
                  icon: (c) => iconFor(c.icon),
                  selected: _category,
                );
                if (c != null) setState(() => _category = c);
              },
            ),
          ListRow(
            icon: wallet == null ? AppIcons.wallet : iconForWalletType(wallet.type),
            title: wallet?.name ?? tr('Pilih dompet'),
            subtitle: wallet == null ? tr('Dompet') : tr('Dompet · saldo {0}', [formatRupiahShort(wallet.balance)]),
            chevron: true,
            onTap: () async {
              final w = await showPickerSheet(
                context,
                title: tr('Pilih dompet'),
                items: vm.wallets,
                label: (w) => w.name,
                sublabel: (w) => tr('Saldo {0}', [formatRupiah(w.balance)]),
                icon: (w) => iconForWalletType(w.type),
                selected: wallet,
              );
              if (w != null) setState(() => _wallet = w);
            },
          ),
          ListRow(
            icon: AppIcons.calendar,
            title: isSameDay(_date, DateTime.now()) ? tr('Hari ini, {0}', [formatShortDate(_date)]) : formatLongDate(_date),
            subtitle: tr('Tanggal'),
            chevron: true,
            onTap: () async {
              final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (p != null) setState(() => _date = p);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(spacing: 12, children: [
              const IconBox(icon: AppIcons.notebookPen),
              Expanded(
                child: TextField(
                  controller: _note,
                  style: AppText.body(15, weight: FontWeight.w600),
                  decoration: InputDecoration(border: InputBorder.none, hintText: tr('Catatan'), hintStyle: AppText.body(15, color: AppColors.faint)),
                ),
              ),
            ]),
          ),
        ]),
        if (_type == 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              GroupLabel(tr('Sering dicatat')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _frequent
                    .map((f) => GestureDetector(
                          onTap: () => setState(() {
                            _amount.text = f.$2.round().toString();
                            _note.text = tr(f.$1);
                          }),
                          child: GlassCard(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: Text('${tr(f.$1)} ${formatRupiahShort(f.$2).replaceFirst('Rp', '')}', style: AppText.body(13, weight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }
}
