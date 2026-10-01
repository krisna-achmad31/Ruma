import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/invite_partner_screen.dart';
import '../../features/auth/presentation/screens/join_family_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/calendar/presentation/screens/maintenance_screen.dart';
import '../../features/finance/presentation/screens/add_transaction_screen.dart';
import '../../features/finance/presentation/screens/assets_screen.dart';
import '../../features/finance/presentation/screens/category_budget_screen.dart';
import '../../features/finance/presentation/screens/category_detail_screen.dart';
import '../../features/finance/presentation/screens/finance_home_screen.dart';
import '../../features/finance/presentation/screens/finance_report_screen.dart';
import '../../features/finance/presentation/screens/goals_screen.dart';
import '../../features/finance/presentation/screens/installments_screen.dart';
import '../../features/finance/presentation/screens/wallet_management_screen.dart';
import '../../features/finance/presentation/screens/wallet_transfer_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/life_stage/presentation/screens/baby_screen.dart';
import '../../features/life_stage/presentation/screens/stage_picker_screen.dart';
import '../../features/life_stage/presentation/screens/lebaran_screen.dart';
import '../../features/life_stage/presentation/screens/wedding_screen.dart';
import '../../features/settings/presentation/screens/important_links_screen.dart';
import '../../features/settings/presentation/screens/more_menu_screen.dart';
import '../../features/settings/presentation/screens/paywall_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/widget_screen.dart';
import '../../features/shopping/presentation/screens/shopping_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../features/together/presentation/screens/conversation_cards_screen.dart';
import '../../features/together/presentation/screens/journal_screen.dart';
import '../../features/together/presentation/screens/love_timeline_screen.dart';
import '../../features/together/presentation/screens/reflection_history_screen.dart';
import '../../features/together/presentation/screens/reflection_screen.dart';
import '../../features/together/presentation/screens/together_home_screen.dart';

/// Tab utama berganti tanpa animasi geser supaya terasa seperti tab bar native.
Page<void> _tab(GoRouterState state, Widget child) => NoTransitionPage<void>(key: state.pageKey, child: child);

GoRouter buildAppRouter(AuthViewModel authViewModel) {
  const authRoutes = {'/onboarding', '/login', '/register'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authViewModel,
    redirect: (context, state) {
      // Splash memutuskan sendiri ke mana setelah status login diketahui.
      if (state.matchedLocation == '/splash') return null;
      final status = authViewModel.status;
      if (status == AuthStatus.unknown) return '/splash';
      final onAuthRoute = authRoutes.contains(state.matchedLocation);
      if (status != AuthStatus.authenticated) return onAuthRoute ? null : '/onboarding';
      if (authViewModel.pendingInvite && state.matchedLocation != '/invite') return '/invite';
      if (onAuthRoute) {
        final next = state.uri.queryParameters['next'];
        return next == 'join' ? '/join' : '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', pageBuilder: (context, state) => _tab(state, const SplashScreen())),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen(next: state.uri.queryParameters['next'])),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/invite', builder: (context, state) => const InvitePartnerScreen()),
      GoRoute(path: '/join', builder: (context, state) => const JoinFamilyScreen()),
      GoRoute(path: '/paywall', builder: (context, state) => PaywallScreen(fromOnboarding: state.uri.queryParameters['from'] == 'onboarding')),

      // Tab Hari ini
      GoRoute(path: '/', pageBuilder: (context, state) => _tab(state, const HomeScreen())),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),

      // Tab Urusan
      GoRoute(
        path: '/urusan',
        pageBuilder: (context, state) => _tab(state, TasksScreen(openAdd: state.uri.queryParameters['add'] == '1')),
        routes: [
          GoRoute(path: 'calendar', builder: (context, state) => const CalendarScreen()),
          GoRoute(path: 'shopping', builder: (context, state) => const ShoppingScreen()),
        ],
      ),
      GoRoute(path: '/calendar', redirect: (context, state) => '/urusan/calendar'),

      // Tab Uang
      GoRoute(
        path: '/finance',
        pageBuilder: (context, state) => _tab(state, const FinanceHomeScreen()),
        routes: [
          GoRoute(path: 'categories', builder: (context, state) => const CategoryBudgetScreen()),
          GoRoute(path: 'category/:categoryId', builder: (context, state) => CategoryDetailScreen(categoryId: state.pathParameters['categoryId']!)),
          GoRoute(path: 'add', builder: (context, state) => const AddTransactionScreen()),
          GoRoute(path: 'wallets', builder: (context, state) => const WalletManagementScreen()),
          GoRoute(path: 'transfer', builder: (context, state) => const WalletTransferScreen()),
          GoRoute(path: 'report', builder: (context, state) => const FinanceReportScreen()),
          GoRoute(path: 'installments', builder: (context, state) => const InstallmentsScreen()),
          GoRoute(path: 'goals', builder: (context, state) => const GoalsScreen()),
          GoRoute(path: 'assets', builder: (context, state) => const AssetsScreen()),
        ],
      ),

      // Tab Kita
      GoRoute(
        path: '/together',
        pageBuilder: (context, state) => _tab(state, const TogetherHomeScreen()),
        routes: [
          GoRoute(path: 'love-timeline', builder: (context, state) => const LoveTimelineScreen()),
          GoRoute(path: 'conversation-cards', builder: (context, state) => const ConversationCardsScreen()),
          GoRoute(
            path: 'reflection',
            builder: (context, state) => const ReflectionScreen(),
            routes: [GoRoute(path: 'history', builder: (context, state) => const ReflectionHistoryScreen())],
          ),
          GoRoute(path: 'journal', builder: (context, state) => const JournalScreen()),
        ],
      ),

      // Tab Rumah
      GoRoute(
        path: '/more',
        pageBuilder: (context, state) => _tab(state, const MoreMenuScreen()),
        routes: [
          GoRoute(path: 'maintenance', builder: (context, state) => const MaintenanceScreen()),
          GoRoute(path: 'widget', builder: (context, state) => const WidgetScreen()),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: 'important-links', builder: (context, state) => const ImportantLinksScreen()),
        ],
      ),
      GoRoute(path: '/life/wedding', builder: (context, state) => const WeddingScreen()),
      GoRoute(path: '/life/baby', builder: (context, state) => const BabyScreen()),
      GoRoute(path: '/life/lebaran', builder: (context, state) => const LebaranScreen()),
      GoRoute(path: '/life/stage', builder: (context, state) => StagePickerScreen(fromOnboarding: state.uri.queryParameters['from'] == 'onboarding')),
    ],
  );
}
