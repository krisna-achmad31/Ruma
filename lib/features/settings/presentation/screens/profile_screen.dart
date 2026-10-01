import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  Future<void> _changePhoto(BuildContext context, AuthViewModel auth) async {
    final fromCamera = await showPickerSheet<bool>(
      context,
      title: tr('Ganti foto profil'),
      items: const [true, false],
      label: (c) => c ? tr('Ambil foto') : tr('Pilih dari galeri'),
      icon: (c) => c ? AppIcons.camera : AppIcons.image,
    );
    if (fromCamera == null) return;
    final b64 = await PhotoService().pickBase64(fromCamera: fromCamera, maxWidth: 360);
    if (b64 == null) return;
    final ok = await auth.updatePhoto(PhotoService.toDataUri(b64));
    if (context.mounted) showSnack(context, ok ? tr('Foto profil diperbarui.') : tr('Gagal menyimpan foto.'));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<SettingsViewModel>();
    final user = auth.currentUser;
    final photo = PhotoService.base64FromDataUri(user?.photoUrl);
    final phone = user?.phone ?? '';
    final maskedPhone = phone.length >= 8 ? '${phone.substring(0, 4)} •••• ${phone.substring(phone.length - 4)}' : phone;

    return AppScaffold(
      tab: AppTab.rumah,
      children: [
        AppNavBar(
          title: tr('Profil'),
          actionIcon: AppIcons.pencil,
          onAction: () async {
            final name = await showTextSheet(context, title: tr('Nama keluarga'), initial: vm.familyInfo.name);
            if (name == null || !context.mounted) return;
            final city = await showTextSheet(context, title: tr('Kota'), initial: vm.familyInfo.location, hint: tr('Dipakai untuk cuaca di Hari ini'));
            await vm.updateFamily(name: name, location: city);
          },
        ),
        Column(spacing: 8, children: [
          GestureDetector(
            onTap: () => _changePhoto(context, auth),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.jade,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x402C6B5A), blurRadius: 24, offset: Offset(0, 10))],
                    image: photo == null ? null : DecorationImage(image: MemoryImage(base64Decode(photo)), fit: BoxFit.cover),
                  ),
                  alignment: Alignment.center,
                  child: photo == null ? Text((user?.name ?? '?').substring(0, 1).toUpperCase(), style: AppText.display(38, color: Colors.white)) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.ink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(AppIcons.camera, size: 15, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
          Text(user?.name ?? '', style: AppText.display(24)),
          Text('${user?.role == 'admin' ? tr('Admin') : tr('Anggota')} · ${vm.familyInfo.name}', style: AppText.body(13, color: AppColors.muted)),
        ]),
        ListCard(children: [
          ListRow(icon: AppIcons.mail, title: tr('Email'), subtitle: user?.email ?? ''),
          ListRow(
            icon: AppIcons.user,
            title: tr('Nama'),
            subtitle: user?.name ?? '',
            chevron: true,
            onTap: () async {
              final name = await showTextSheet(context, title: tr('Nama kamu'), initial: user?.name ?? '');
              if (name == null || name.trim().isEmpty || !context.mounted) return;
              final ok = await auth.updateProfile(name: name.trim());
              if (context.mounted) showSnack(context, ok ? tr('Nama diperbarui.') : tr('Gagal menyimpan nama.'));
            },
          ),
          ListRow(
            icon: AppIcons.phone,
            title: tr('No. HP / WhatsApp'),
            subtitle: maskedPhone.isEmpty ? tr('Belum diisi, ketuk untuk isi') : maskedPhone,
            chevron: true,
            onTap: () async {
              final input = await showTextSheet(context, title: tr('No. HP / WhatsApp'), initial: phone, hint: '0812 3456 7890', keyboardType: TextInputType.phone);
              if (input == null || !context.mounted) return;
              final cleaned = input.replaceAll(RegExp(r'[^0-9+]'), '');
              if (cleaned.isNotEmpty && cleaned.length < 9) {
                showSnack(context, tr('Nomor terlalu pendek, cek lagi ya.'));
                return;
              }
              final ok = await auth.updateProfile(phone: cleaned);
              if (context.mounted) showSnack(context, ok ? tr('No. HP disimpan.') : tr('Gagal menyimpan No. HP.'));
            },
          ),
          ListRow(icon: AppIcons.house, title: tr('Keluarga'), subtitle: [vm.familyInfo.name, if (vm.familyInfo.location.isNotEmpty) vm.familyInfo.location].join(' · ')),
          ListRow(icon: AppIcons.users, title: tr('Anggota'), subtitle: vm.members.map((m) => m.name.split(' ').first).join(', ')),
        ]),
        InfoBanner(icon: AppIcons.shieldCheck, text: tr('Data rumah tangga hanya bisa dilihat anggota keluarga ini.')),
        ListCard(children: [
          ListRow(
            icon: AppIcons.keyRound,
            title: tr('Ganti password'),
            chevron: true,
            onTap: () async {
              final ok = await auth.sendPasswordReset(user?.email ?? '');
              if (context.mounted) showSnack(context, ok ? tr('Tautan ganti password dikirim ke {0}.', [user?.email]) : tr('Gagal mengirim tautan.'));
            },
          ),
          ListRow(
            icon: AppIcons.logOut,
            iconColor: AppColors.rose,
            iconBackground: AppColors.roseSoft,
            title: tr('Keluar dari akun'),
            titleColor: AppColors.rose,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: tr('Keluar dari akun?'),
                message: tr('Data rumah tetap aman. Pasanganmu masih bisa pakai aplikasi seperti biasa.'),
                confirmLabel: tr('Keluar'),
                icon: AppIcons.logOut,
                destructive: true,
              );
              if (ok) await auth.signOut();
            },
          ),
        ]),
      ],
    );
  }
}
