import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_brand.dart';
import 'core/constants/app_colors.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_locale.dart';
import 'core/dev/seed_runner.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppLocale.instance.load();
  if (kDebugMode) {
    try {
      await seedFirestoreIfNeeded();
    } catch (e) {
      debugPrint('Seed dilewati: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(),
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(context.read<AuthViewModel>());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) => _buildApp(),
    );
  }

  Widget _buildApp() {
    return MaterialApp.router(
      title: AppBrand.name,
      locale: AppLocale.instance.locale,
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.figtreeTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.jade, primary: AppColors.jade, surface: AppColors.background),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentTextStyle: GoogleFonts.figtree(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0x0D15201D),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          labelStyle: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
          showCheckmark: false,
        ),
        datePickerTheme: const DatePickerThemeData(backgroundColor: Colors.white),
      ),
      routerConfig: _router,
    );
  }
}
