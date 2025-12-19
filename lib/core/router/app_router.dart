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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
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
      path: '/dashboard',
      builder: (context, state) {
        // Use Consumer to access account type
        return Consumer(
          builder: (context, ref, child) {
            final accountType = ref.watch(accountTypeProvider);
            if (accountType == AccountType.pro) {
              return const ProDashboardScreen();
            }
            return const DashboardScreen();
          },
        );
      },
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
  ],
);
