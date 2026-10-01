import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/calendar/data/datasources/calendar_remote_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/finance/data/datasources/finance_remote_datasource.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/life_stage/data/datasources/life_stage_remote_datasource.dart';
import '../../features/life_stage/data/repositories/life_stage_repository_impl.dart';
import '../../features/life_stage/domain/repositories/life_stage_repository.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/shopping/data/datasources/shopping_remote_datasource.dart';
import '../../features/shopping/data/repositories/shopping_repository_impl.dart';
import '../../features/shopping/domain/repositories/shopping_repository.dart';
import '../../features/tasks/data/datasources/task_remote_datasource.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/together/data/datasources/together_remote_datasource.dart';
import '../../features/together/data/repositories/together_repository_impl.dart';
import '../../features/together/domain/repositories/together_repository.dart';

HomeRepository buildHomeRepository() => HomeRepositoryImpl(HomeRemoteDataSource());

CalendarRepository buildCalendarRepository() => CalendarRepositoryImpl(CalendarRemoteDataSource());

TogetherRepository buildTogetherRepository() => TogetherRepositoryImpl(TogetherRemoteDataSource());

FinanceRepository buildFinanceRepository() => FinanceRepositoryImpl(FinanceRemoteDataSource());

SettingsRepository buildSettingsRepository() => SettingsRepositoryImpl(SettingsRemoteDataSource());

TaskRepository buildTaskRepository() => TaskRepositoryImpl(TaskRemoteDataSource());

ShoppingRepository buildShoppingRepository() => ShoppingRepositoryImpl(ShoppingRemoteDataSource());

LifeStageRepository buildLifeStageRepository() => LifeStageRepositoryImpl(LifeStageRemoteDataSource());

List<SingleChildWidget> buildAppProviders() {
  final AuthRepository authRepository = AuthRepositoryImpl(AuthRemoteDataSource());

  return [
    ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(
        authRepository: authRepository,
        loginUseCase: LoginUseCase(authRepository),
        registerUseCase: RegisterUseCase(authRepository),
      ),
    ),
  ];
}
