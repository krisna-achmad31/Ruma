import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/family_scope.dart';
import '../viewmodels/together_viewmodel.dart';

class TogetherScope extends StatelessWidget {
  final Widget child;

  const TogetherScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<TogetherViewModel>(
      create: (user) => TogetherViewModel(
        togetherRepository: buildTogetherRepository(),
        settingsRepository: buildSettingsRepository(),
        homeRepository: buildHomeRepository(),
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: child,
    );
  }
}
