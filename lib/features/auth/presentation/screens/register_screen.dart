import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_button.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _google = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.register(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim(), password: _password.text);
    if (!mounted) return;
    if (!ok) showSnack(context, vm.errorMessage ?? tr('Gagal daftar.'));
  }

  Future<void> _googleSignUp(AuthViewModel vm) async {
    setState(() => _google = true);
    final ok = await vm.signInWithGoogle();
    if (!mounted) return;
    setState(() => _google = false);
    if (!ok) showSnack(context, vm.errorMessage ?? tr('Gagal daftar dengan Google.'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                AppNavBar(title: tr('Langkah 1 dari 3')),
                const SizedBox(height: 24),
                Text(tr('Buat akun rumahmu'), style: AppText.display(30, letterSpacing: -0.8)),
                const SizedBox(height: 8),
                Text(tr('Pasanganmu bisa gabung setelah ini, cukup pakai kode.'), style: AppText.body(15, color: AppColors.muted)),
                const SizedBox(height: 24),
                GoogleButton(label: tr('Daftar dengan Google'), loading: _google && vm.isSubmitting, onPressed: () => _googleSignUp(vm)),
                const SizedBox(height: 18),
                Row(spacing: 10, children: [
                  const Expanded(child: Divider(color: AppColors.hairline)),
                  Text(tr('atau pakai email'), style: AppText.body(12, color: AppColors.faint)),
                  const Expanded(child: Divider(color: AppColors.hairline)),
                ]),
                const SizedBox(height: 18),
                Column(
                  spacing: 14,
                  children: [
                    LabeledField(
                      label: tr('Nama'),
                      child: AppTextField(controller: _name, icon: AppIcons.user, hint: tr('Nama lengkap'), validator: (v) => (v == null || v.trim().isEmpty) ? tr('Nama wajib diisi') : null),
                    ),
                    LabeledField(
                      label: tr('Email'),
                      child: AppTextField(
                        controller: _email,
                        icon: AppIcons.mail,
                        hint: tr('nama@email.com'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? tr('Format email tidak valid') : null,
                      ),
                    ),
                    LabeledField(
                      label: tr('No. HP / WhatsApp'),
                      child: AppTextField(
                        controller: _phone,
                        icon: AppIcons.phone,
                        hint: '0812 3456 7890',
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty) ? tr('No. HP wajib diisi') : null,
                      ),
                    ),
                    LabeledField(
                      label: tr('Password'),
                      child: AppTextField(
                        controller: _password,
                        icon: AppIcons.lock,
                        hint: tr('Minimal 6 karakter'),
                        obscure: _obscure,
                        validator: (v) => (v == null || v.length < 6) ? tr('Password minimal 6 karakter') : null,
                        suffix: IconButton(
                          icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 18, color: AppColors.faint),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: tr('Lanjut'), loading: !_google && vm.isSubmitting, onPressed: () => _submit(vm)),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pushReplacement('/login'),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: tr('Sudah punya akun? '), style: AppText.body(14, color: AppColors.muted)),
                      TextSpan(text: tr('Masuk'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.jade)),
                    ])),
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
