import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/family_scope.dart';
import '../viewmodels/life_stage_viewmodel.dart';

class LifeStageScope extends StatelessWidget {
  final Widget child;

  const LifeStageScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<LifeStageViewModel>(
      create: (user) => LifeStageViewModel(repository: buildLifeStageRepository(), familyId: user.familyId, userName: user.name),
      child: child,
    );
  }
}
