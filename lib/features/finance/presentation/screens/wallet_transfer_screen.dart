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
import '../../domain/entities/wallet_entity.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/finance_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class WalletTransferScreen extends StatelessWidget {
  const WalletTransferScreen({super.key});

  @override
  Widget build(BuildContext context) => const FinanceScope(child: _Content());
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  WalletEntity? _from;
  WalletEntity? _to;
  final _amount = TextEditingController();
  double _fee = 0;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick(FinanceViewModel vm, bool from) async {
    final w = await showPickerSheet(
      context,
      title: from ? tr('Pindah dari') : tr('Pindah ke'),
      items: vm.wallets,
      label: (w) => w.name,
      sublabel: (w) => tr('Saldo {0}', [formatRupiah(w.balance)]),
      icon: (w) => iconForWalletType(w.type),
      selected: from ? _from : _to,
    );
    if (w != null) setState(() => from ? _from = w : _to = w);
  }

  Future<void> _submit(FinanceViewModel vm) async {
    final amount = double.tryParse(_amount.text) ?? 0;
    if (_from == null || _to == null || amount <= 0) {
      showSnack(context, tr('Lengkapi dompet asal, tujuan, dan nominal.'));
      return;
    }
    if (_from!.id == _to!.id) {
      showSnack(context, tr('Dompet asal dan tujuan tidak boleh sama.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await vm.transfer(fromWalletId: _from!.id, toWalletId: _to!.id, amount: amount, adminFee: _fee, date: _date);
      if (!mounted) return;
      showSnack(context, tr('Saldo dipindahkan.'));
      context.pop();
    } catch (_) {
      if (mounted) showSnack(context, tr('Pindah saldo gagal, coba lagi.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _walletCard(String label, WalletEntity? w, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(spacing: 12, children: [
        IconBox(
          icon: w == null ? AppIcons.wallet : iconForWalletType(w.type),
          size: 44,
          color: toneForWalletType(w?.type ?? '').$1,
          background: toneForWalletType(w?.type ?? '').$2,
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
            Text(label.toUpperCase(), style: AppText.eyebrow(AppColors.faint)),
            Text(w?.name ?? tr('Pilih dompet'), style: AppText.body(17, weight: FontWeight.w700)),
            if (w != null) Text(tr('Saldo {0}', [formatRupiah(w.balance)]), style: AppText.body(12, color: AppColors.muted)),
          ]),
        ),
        const Icon(AppIcons.chevronDown, size: 18, color: AppColors.faint),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    return AppScaffold(
      bottom: PrimaryButton(label: tr('Pindahkan'), loading: _saving, onPressed: () => _submit(vm)),
      children: [
        AppNavBar(title: tr('Pindah saldo'), leadingIcon: AppIcons.x),
        Column(
          spacing: 8,
          children: [
            _walletCard(tr('Dari'), _from, () => _pick(vm, true)),
            GestureDetector(
              onTap: () => setState(() {
                final t = _from;
                _from = _to;
                _to = t;
              }),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(AppIcons.arrowUpDown, size: 18, color: Colors.white),
              ),
            ),
            _walletCard(tr('Ke'), _to, () => _pick(vm, false)),
          ],
        ),
        Column(spacing: 4, children: [
          Text(tr('Nominal'), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted)),
          IntrinsicWidth(
            child: TextField(
              controller: _amount,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppText.display(44, letterSpacing: -1.4),
              decoration: InputDecoration(border: InputBorder.none, hintText: '0', prefixText: 'Rp', hintStyle: AppText.display(44, color: AppColors.faint)),
            ),
          ),
        ]),
        ListCard(children: [
          ListRow(
            icon: AppIcons.receipt,
            title: tr('Biaya admin'),
            subtitle: tr('Dicatat ke amplop Rumah & Tagihan'),
            trailingText: formatRupiah(_fee),
            onTap: () async {
              final v = await showAmountSheet(context, title: tr('Biaya admin'), initial: _fee > 0 ? _fee : 2500);
              if (v != null) setState(() => _fee = v);
            },
          ),
          ListRow(
            icon: AppIcons.calendar,
            title: tr('Tanggal'),
            trailingText: formatFullDate(_date),
            onTap: () async {
              final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (p != null) setState(() => _date = p);
            },
          ),
        ]),
        InfoBanner(icon: AppIcons.info, text: tr('Pindah saldo tidak dihitung sebagai pengeluaran.')),
      ],
    );
  }
}
