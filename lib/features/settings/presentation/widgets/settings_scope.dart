import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/family_scope.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScope extends StatelessWidget {
  final Widget child;

  const SettingsScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<SettingsViewModel>(
      create: (user) => SettingsViewModel(settingsRepository: buildSettingsRepository(), familyId: user.familyId),
      child: child,
    );
  }
}
