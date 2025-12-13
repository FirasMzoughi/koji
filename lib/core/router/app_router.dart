import 'package:go_router/go_router.dart';
import 'package:koji/features/auth/presentation/screens/login_screen.dart';
import 'package:koji/features/auth/presentation/screens/signup_screen.dart';
import 'package:koji/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:koji/features/estimates/presentation/screens/create_estimate_screen.dart';
import 'package:koji/features/estimates/presentation/screens/preview_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
      builder: (context, state) => const DashboardScreen(),
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
