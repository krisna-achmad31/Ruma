import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _familyName;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    setState(() => _familyName = null);
    if (value.length == 6) {
      setState(() => _checking = true);
      final name = await context.read<AuthViewModel>().findFamilyName(value);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _familyName = name;
      });
      if (name == null) showSnack(context, tr('Kode rumah tidak ditemukan. Cek lagi ke pasanganmu.'));
    }
  }

  Future<void> _join() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.joinFamily(_controller.text);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      showSnack(context, vm.errorMessage ?? tr('Gagal bergabung.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final code = _controller.text;
    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      bottom: PrimaryButton(label: tr('Gabung ke rumah ini'), loading: vm.isSubmitting, onPressed: _familyName == null ? null : _join),
      children: [
        const AppNavBar(title: ''),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(tr('Masukkan kode rumah'), style: AppText.display(30, letterSpacing: -0.8)),
            Text(tr('Minta kodenya dari pasanganmu. Ada di Rumah › Undang anggota.'), style: AppText.body(15, color: AppColors.muted, height: 1.4)),
          ],
        ),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            children: [
              Row(
                spacing: 8,
                children: List.generate(6, (i) {
                  final ch = i < code.length ? code[i] : '';
                  final active = i == code.length || (i == 5 && code.length == 6);
                  return Expanded(
                    child: GlassCard(
                      strong: true,
                      radius: 14,
                      padding: EdgeInsets.zero,
                      borderColor: active ? AppColors.jade : null,
                      borderWidth: active ? 2 : 1,
                      child: SizedBox(height: 58, child: Center(child: Text(ch, style: AppText.display(24)))),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                    ],
                    onChanged: _onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_checking) const Center(child: CircularProgressIndicator(color: AppColors.jade)),
        if (_familyName != null)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                const IconBox(icon: AppIcons.house, size: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(_familyName!, style: AppText.body(15, weight: FontWeight.w700)),
                      Text(tr('Kamu akan bergabung ke rumah ini'), style: AppText.body(12, color: AppColors.muted)),
                    ],
                  ),
                ),
                const Icon(AppIcons.circleCheck, color: AppColors.jade, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}
