import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/family_scope.dart';
import '../viewmodels/finance_viewmodel.dart';

/// Menyediakan FinanceViewModel untuk layar-layar Uang.
class FinanceScope extends StatelessWidget {
  final Widget child;

  const FinanceScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<FinanceViewModel>(
      create: (user) => FinanceViewModel(
        financeRepository: buildFinanceRepository(),
        settingsRepository: buildSettingsRepository(),
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: child,
    );
  }
}
