import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/screens/splash_screen.dart';
import 'package:koji/screens/account_type_screen.dart';
import 'package:koji/features/pro/presentation/screens/domain_selection_screen.dart';
import 'package:koji/features/pro/presentation/screens/company_info_screen.dart';
import 'package:koji/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:koji/features/subscription/presentation/screens/payment_screen.dart';
import 'package:koji/features/auth/presentation/screens/login_screen.dart';
import 'package:koji/features/auth/presentation/screens/signup_screen.dart';
import 'package:koji/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:koji/features/dashboard/presentation/screens/pro_dashboard_screen.dart';
import 'package:koji/providers/account_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/estimates/presentation/screens/create_estimate_screen.dart';
import 'package:koji/features/estimates/presentation/screens/preview_screen.dart';
import 'package:koji/features/estimates/presentation/screens/room_selection_screen.dart';
import 'package:koji/features/estimates/presentation/screens/estimates_list_screen.dart';
import 'package:koji/features/profile/presentation/screens/profile_onboarding_screen.dart';
import 'package:koji/features/clients/presentation/screens/clients_placeholder_screen.dart';
import 'package:koji/features/trades/presentation/screens/trade_dashboard_screen.dart';
import 'package:koji/models/trade_data.dart';
import 'package:koji/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:koji/features/messages/presentation/screens/messages_placeholder_screen.dart';
import 'package:koji/core/navigation/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Root redirect
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),
    // Routes sans navigation bottom bar
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/account-type',
      builder: (context, state) => const AccountTypeScreen(),
    ),
    GoRoute(
      path: '/pro/domain-selection',
      builder: (context, state) => const DomainSelectionScreen(),
    ),
    GoRoute(
      path: '/pro/company-info',
      builder: (context, state) => const CompanyInfoScreen(),
    ),
    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const PaymentScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/room-selection',
      builder: (context, state) => const RoomSelectionScreen(),
    ),
    GoRoute(
      path: '/create-estimate',
      builder: (context, state) => const CreateEstimateScreen(),
    ),
    GoRoute(
      path: '/preview',
      builder: (context, state) => const PreviewScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Routes avec navigation bottom bar
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  final accountType = ref.watch(accountTypeProvider);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(bottomNavIndexProvider.notifier).state = 0;
                  });
                  if (accountType == AccountType.pro) {
                    return const ProDashboardScreen();
                  }
                  return const DashboardScreen();
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/estimates',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(bottomNavIndexProvider.notifier).state = 1;
                  });
                  return const EstimatesListScreen();
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/clients',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  });
                  return const ClientsPlaceholderScreen();
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(bottomNavIndexProvider.notifier).state = 3;
                  });
                  return const MessagesPlaceholderScreen();
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(bottomNavIndexProvider.notifier).state = 4;
                  });
                  return const ProfileOnboardingScreen();
                },
              ),
            );
          },
        ),
      ],
    ),

    // Dashboards métiers
    GoRoute(
      path: '/trade/:tradeName',
      builder: (context, state) {
        final tradeName = state.pathParameters['tradeName'];
        final trade = Trade.values.firstWhere(
          (t) => t.name == tradeName,
          orElse: () => Trade.other,
        );
        return TradeDashboardScreen(trade: trade);
      },
    ),
  ],
);
