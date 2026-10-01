import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_button.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class LoginScreen extends StatefulWidget {
  /// 'join' kalau pengguna datang dari "Aku diundang pasangan".
  final String? next;

  const LoginScreen({super.key, this.next});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _google = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn(AuthViewModel vm) async {
    setState(() => _google = true);
    final ok = await vm.signInWithGoogle();
    if (!mounted) return;
    setState(() => _google = false);
    if (!ok) {
      showSnack(context, vm.errorMessage ?? tr('Gagal masuk dengan Google.'));
    } else if (widget.next == 'join' && !vm.pendingInvite) {
      context.go('/join');
    }
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    if (!ok) {
      showSnack(context, vm.errorMessage ?? tr('Gagal masuk.'));
    } else if (widget.next == 'join') {
      context.go('/join');
    }
  }

  Future<void> _forgot(AuthViewModel vm) async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showSnack(context, tr('Isi email dulu, nanti tautan reset password dikirim ke sana.'));
      return;
    }
    final ok = await vm.sendPasswordReset(email);
    if (mounted) showSnack(context, ok ? tr('Tautan reset password sudah dikirim ke {0}.', [email]) : tr('Gagal mengirim tautan. Periksa emailnya.'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 24,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.faint)),
                            child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                              const Icon(AppIcons.houseHeart, size: 16, color: AppColors.jade),
                              Text(AppBrand.name, style: AppText.body(13, weight: FontWeight.w700, color: AppColors.muted)),
                            ]),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text(tr('Selamat datang lagi'), style: AppText.display(30, letterSpacing: -0.8)),
                            Text(tr('Masuk untuk lanjut mengurus rumah bareng.'), style: AppText.body(15, color: AppColors.muted)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [
                            LabeledField(
                              label: tr('Email'),
                              child: AppTextField(
                                controller: _email,
                                icon: AppIcons.mail,
                                keyboardType: TextInputType.emailAddress,
                                hint: tr('nama@email.com'),
                                validator: (v) => (v == null || !v.contains('@')) ? tr('Format email tidak valid') : null,
                              ),
                            ),
                            LabeledField(
                              label: tr('Password'),
                              child: AppTextField(
                                controller: _password,
                                icon: AppIcons.lock,
                                obscure: _obscure,
                                hint: tr('Password'),
                                validator: (v) => (v == null || v.isEmpty) ? tr('Password wajib diisi') : null,
                                suffix: IconButton(
                                  icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 18, color: AppColors.faint),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _forgot(vm),
                              child: Text(tr('Lupa password?'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          spacing: 12,
                          children: [
                            PrimaryButton(label: tr('Masuk'), loading: !_google && vm.isSubmitting, onPressed: () => _submit(vm)),
                            Row(spacing: 10, children: [
                              const Expanded(child: Divider(color: AppColors.hairline)),
                              Text(tr('atau'), style: AppText.body(12, color: AppColors.faint)),
                              const Expanded(child: Divider(color: AppColors.hairline)),
                            ]),
                            GoogleButton(label: tr('Masuk dengan Google'), loading: _google && vm.isSubmitting, onPressed: () => _googleSignIn(vm)),
                            GestureDetector(
                              onTap: () => context.pushReplacement('/register'),
                              child: Text.rich(TextSpan(children: [
                                TextSpan(text: tr('Belum punya akun? '), style: AppText.body(14, color: AppColors.muted)),
                                TextSpan(text: tr('Daftar'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.jade)),
                              ])),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
