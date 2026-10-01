import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Langkah 2 sesudah daftar, juga dibuka dari Rumah > Undang anggota.
class InvitePartnerScreen extends StatelessWidget {
  const InvitePartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<SettingsViewModel>(
      create: (user) => SettingsViewModel(settingsRepository: buildSettingsRepository(), familyId: user.familyId),
      child: const _InviteContent(),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent();

  void _done(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final fromSignup = auth.pendingInvite;
    auth.finishInvite();
    if (fromSignup) {
      context.go('/life/stage?from=onboarding');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final code = vm.familyInfo.inviteCode;
    final display = code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : (code.isEmpty ? '......' : code);
    final name = auth.currentUser?.name ?? '';

    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          PrimaryButton(
            label: tr('Kirim lewat WhatsApp'),
            icon: AppIcons.send,
            onPressed: code.isEmpty
                ? null
                : () => SharePlus.instance.share(ShareParams(
                      text: tr('Yuk gabung ke rumah kita di {0}. Pakai kode rumah: {1}', [AppBrand.name, code]),
                    )),
          ),
          GestureDetector(
            onTap: () => _done(context),
            child: Text(auth.pendingInvite ? tr('Nanti saja') : tr('Selesai'), style: AppText.body(14, weight: FontWeight.w700, color: AppColors.muted)),
          ),
        ],
      ),
      children: [
        AppNavBar(title: auth.pendingInvite ? tr('Langkah 2 dari 3') : tr('Undang anggota'), onLeading: () => _done(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Avatar(name: name, size: 64),
            Row(spacing: 5, children: List.generate(4, (_) => Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.faint, shape: BoxShape.circle)))),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.roseSoft, shape: BoxShape.circle, border: Border.all(color: AppColors.rose, width: 2)),
              child: const Icon(AppIcons.userPlus, color: AppColors.rose, size: 24),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(tr('Ajak pasanganmu'), style: AppText.display(30, letterSpacing: -0.8)),
            Text(
              tr('Rumah tangga dipikul berdua. Kirim kode ini supaya dia bisa gabung ke rumah yang sama.'),
              style: AppText.body(15, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
        PastelHero(
          tone: PastelTone.rose,
          object: 'envelope',
          objectSize: 104,
          objectRotation: -12,
          label: tr('Kode rumah'),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(display, style: AppText.display(40, letterSpacing: 2))),
            Text(tr('Kirim kode ini supaya pasanganmu gabung ke rumah yang sama.'), style: AppText.body(13, color: AppColors.muted, height: 1.4)),
          ]),
          body: Align(
            alignment: Alignment.centerLeft,
            child: HeroButton(
              label: tr('Salin kode'),
              icon: AppIcons.copy,
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                showSnack(context, tr('Kode rumah disalin.'));
              },
            ),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            const Object3D('sparkles', size: 18),
            Expanded(child: Text(tr('Langganan Plus otomatis berlaku untuk berdua.'), style: AppText.body(13, color: AppColors.muted))),
          ],
        ),
      ],
    );
  }
}
