import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../constants/app_colors.dart';
import 'app_scaffold.dart';

/// Membuat ViewModel untuk keluarga pengguna yang sedang masuk, lalu menyediakannya ke [child].
class FamilyScope<T extends ChangeNotifier> extends StatelessWidget {
  final T Function(UserEntity user) create;
  final Widget child;

  const FamilyScope({super.key, required this.create, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: AppBackground(child: Center(child: CircularProgressIndicator(color: AppColors.jade))),
      );
    }
    return ChangeNotifierProvider<T>(
      key: ValueKey('${user.familyId}_${user.uid}'),
      create: (_) => create(user),
      child: child,
    );
  }
}
