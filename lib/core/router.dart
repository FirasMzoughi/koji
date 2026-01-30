import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/splash/splash_screen.dart';
import 'package:koji/features/onboarding/onboarding_screen.dart';
import 'package:koji/features/welcome/welcome_screen.dart';
import 'package:koji/features/auth/signup_screen.dart';
import 'package:koji/features/auth/login_screen.dart';
import 'package:koji/features/auth/account_type_selection_screen.dart';
import 'package:koji/features/auth/business_info_screen.dart';
import 'package:koji/features/auth/profession_selection_screen.dart';
import 'package:koji/features/home/home_screen.dart';
import 'package:koji/features/quote/visual_proof_screen.dart';
import 'package:koji/features/quote/photo_preview_screen.dart';
import 'package:koji/features/quote/visual_evidence_grid_screen.dart';
import 'package:koji/features/quote/room_selection_screen.dart';
import 'package:koji/features/quote/room_task_screen.dart';
import 'package:koji/features/quote/room_estimation_screen.dart';
import 'package:koji/features/quote/quote_summary_screen.dart';
import 'package:koji/features/quote/quote_detail_screen.dart';
import 'package:koji/features/quote/quote_success_screen.dart';
import 'package:koji/features/quote/client_details_screen.dart';
import 'package:koji/features/fournitures/fournitures_project_screen.dart';
import 'package:koji/features/fournitures/fournitures_detail_screen.dart';
import 'package:koji/features/signature/signature_list_screen.dart';
import 'package:koji/features/signature/signature_screen.dart';
import 'package:koji/features/signature/signature_success_screen.dart';

// Custom page transition for faster navigation - OPTIMIZED
Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150), // Reduced from 200ms
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SignupScreen(),
      ),
    ),
    GoRoute(
      path: '/account-type',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AccountTypeSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/business-info',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const BusinessInfoScreen(),
      ),
    ),
    GoRoute(
      path: '/profession-selection',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ProfessionSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/quote/client-details',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ClientDetailsScreen(),
      ),
    ),
    GoRoute(
      path: '/quote/visual-proofs',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const VisualProofScreen(),
      ),
    ),
    GoRoute(
      path: '/quote/visual-evidence-grid',
      pageBuilder: (context, state) {
        final images = state.extra as List<String>? ?? [];
        return _buildPageWithTransition(
          context,
          state,
          VisualEvidenceGridScreen(initialImages: images),
        );
      },
    ),
    GoRoute(
      path: '/quote/room-selection',
      pageBuilder: (context, state) {
        final images = state.extra as List<String>? ?? [];
        return _buildPageWithTransition(
          context,
          state,
          RoomSelectionScreen(initialImages: images),
        );
      },
    ),
    GoRoute(
      path: '/quote/room-details',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final roomIds = extra['roomIds'] as List<String>? ?? [];
        final images = extra['images'] as List<String>? ?? [];
        return _buildPageWithTransition(
          context,
          state,
          RoomTaskScreen(selectedRoomIds: roomIds, images: images),
        );
      },
    ),
    GoRoute(
      path: '/quote/room-estimation',
      pageBuilder: (context, state) {
         final extra = state.extra as Map<String, dynamic>? ?? {};
         final roomIds = extra['roomIds'] as List<String>? ?? [];
         final images = extra['images'] as List<String>? ?? [];
         return _buildPageWithTransition(
           context,
           state,
           RoomEstimationScreen(selectedRoomIds: roomIds, images: images),
         );
      },
    ),
    GoRoute(
      path: '/quote/summary',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          QuoteSummaryScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/quote/photo-preview',
      pageBuilder: (context, state) {
        final imagePath = state.uri.queryParameters['imagePath'];
        return _buildPageWithTransition(
          context,
          state,
          PhotoPreviewScreen(imagePath: imagePath),
        );
      },
    ),
    GoRoute(
      path: '/quote/detail',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          QuoteDetailScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/quote/success',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          QuoteSuccessScreen(
            quoteId: data['quoteId'] ?? '',
            quoteData: data['quoteData'] as Map<String, dynamic>? ?? {},
          ),
        );
      },
    ),
    GoRoute(
      path: '/fournitures',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const FournituresProjectScreen(),
      ),
    ),
    GoRoute(
      path: '/fournitures/detail',
      pageBuilder: (context, state) {
        final quoteData = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          FournituresDetailScreen(quote: quoteData),
        );
      },
    ),
    // Signature Routes
    GoRoute(
      path: '/signature',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SignatureListScreen(),
      ),
    ),
    GoRoute(
      path: '/signature/sign',
      pageBuilder: (context, state) {
        final quoteData = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          SignatureScreen(quote: quoteData),
        );
      },
    ),
    GoRoute(
      path: '/signature/success',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SignatureSuccessScreen(),
      ),
    ),
  ],
);
