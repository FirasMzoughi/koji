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
import 'package:koji/features/quote/product_selection_screen.dart';
import 'package:koji/features/signature/signature_list_screen.dart';
import 'package:koji/features/signature/signature_screen.dart';
import 'package:koji/features/signature/signature_success_screen.dart';
import 'package:koji/features/synchronization/synchronization_screen.dart';
import 'package:koji/features/synchronization/pointage_heures_screen.dart';
import 'package:koji/features/synchronization/worker_list_screen.dart';
import 'package:koji/features/synchronization/create_worker_screen.dart';
import 'package:koji/features/synchronization/worker_success_screen.dart';
import 'package:koji/features/synchronization/worker_detail_screen.dart'; // Will implement next
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:koji/features/synchronization/project_selection_screen.dart';
import 'package:koji/features/synchronization/project_detail_screen.dart';
import 'package:koji/features/synchronization/worker_assignment_screen.dart';
import 'package:koji/features/synchronization/assignment_success_screen.dart';
import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:koji/features/planning/planning_screen.dart';
import 'package:koji/features/settings/pricing_settings_screen.dart';
import 'package:koji/features/profile/company_profile_screen.dart';
import 'package:koji/features/quote/chantier_creation_screen.dart';
import 'package:koji/features/quote/chantier_dashboard_screen.dart';
import 'package:koji/features/quote/chantier_info_screen.dart';
import 'package:koji/features/quote/chantier_afaire_screen.dart';
import 'package:koji/features/quote/chantier_budget_screen.dart';
import 'package:koji/features/quote/chantier_devis_screen.dart';
import 'package:koji/features/quote/chantier_rdv_screen.dart';
import 'package:koji/features/quote/chantier_add_task_screen.dart';
import 'package:koji/features/quote/chantier_documents_screen.dart';

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
      path: '/chantier/create',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ChantierCreationScreen(),
      ),
    ),
    GoRoute(
      path: '/chantier/dashboard',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierDashboardScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/info',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierInfoScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/afaire',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierAFaireScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/budget',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierBudgetScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/devis',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierDevisScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/rdv',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierRdvScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/add-task',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierAddTaskScreen(data: data),
        );
      },
    ),
    GoRoute(
      path: '/chantier/documents',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _buildPageWithTransition(
          context,
          state,
          ChantierDocumentsScreen(data: data),
        );
      },
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
        const ProductSelectionScreen(),
      ),
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
    // Synchronization Routes
    GoRoute(
      path: '/synchronization',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SynchronizationScreen(),
      ),
    ),
    GoRoute(
      path: '/synchronization/pointage',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const PointageHeuresScreen(),
      ),
    ),
    // Worker Routes
    GoRoute(
      path: '/workers',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const WorkerListScreen(),
      ),
    ),
    GoRoute(
      path: '/workers/create',
      pageBuilder: (context, state) {
        final worker = state.extra as Worker?;
        return _buildPageWithTransition(
          context,
          state,
          CreateWorkerScreen(worker: worker),
        );
      },
    ),
    GoRoute(
      path: '/workers/success',
      pageBuilder: (context, state) {
        final worker = state.extra as Worker?;
        return _buildPageWithTransition(
          context,
          state,
          WorkerSuccessScreen(worker: worker),
        );
      },
    ),
     GoRoute(
      path: '/workers/detail',
      pageBuilder: (context, state) {
        final worker = state.extra as Worker;
        return _buildPageWithTransition(
          context,
          state,
           WorkerDetailScreen(worker: worker),
        );
      },
    ),
    // Project Assignment Routes
    GoRoute(
      path: '/projects',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ProjectSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/projects/detail/:projectId',
      pageBuilder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        final project = state.extra as Project?;
        return _buildPageWithTransition(
          context,
          state,
          ProjectDetailScreen(projectId: projectId, project: project),
        );
      },
    ),
    GoRoute(
      path: '/projects/assign/:projectId',
      pageBuilder: (context, state) {
        final project = state.extra as Project;
        return _buildPageWithTransition(
          context,
          state,
          WorkerAssignmentScreen(project: project),
        );
      },
    ),
    GoRoute(
      path: '/projects/success',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AssignmentSuccessScreen(),
      ),
    ),
    GoRoute(
      path: '/planning',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const PlanningScreen(),
      ),
    ),
    // Settings Routes
    GoRoute(
      path: '/settings/pricing',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const PricingSettingsScreen(),
      ),
    ),
    // Profile Routes
    GoRoute(
      path: '/profile/company',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const CompanyProfileScreen(),
      ),
    ),
  ],
);
