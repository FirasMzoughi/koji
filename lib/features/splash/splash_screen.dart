import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isAnimationDone = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced from 1200ms
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Reduced minimum duration from 2 seconds to 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isAnimationDone = true;
        });
        _attemptNavigation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attemptNavigation() async {
    if (!_isAnimationDone || _hasNavigated) return;

    final authState = ref.read(authProvider);
    if (authState.isLoading) return; // Wait for auth to be determined

    _hasNavigated = true;
    final user = authState.value;

    if (user == null) {
      // No account - go directly to welcome skipping onboarding
      if (mounted) context.go('/welcome');
    } else {
      // Has account - check user type and profile completion
      try {
        final userRepository = ref.read(userRepositoryProvider);
        var userData = await userRepository.getUser(user.id);
        // Post-signup race: a client who just created their account from the
        // devis link may hit splash before the `users` row is written. Retry
        // once so we read their real `is_pro` instead of defaulting to
        // entreprise and misrouting them away from /client-home.
        if (userData == null) {
          await Future.delayed(const Duration(milliseconds: 600));
          userData = await userRepository.getUser(user.id);
        }
        final isProRaw = userData?['is_pro'] as bool? ?? true;
        final isProfileComplete = userData?['is_profile_complete'] == true;
        final isBusinessInfoComplete =
            userData?['is_business_info_complete'] == true;
        final logoUrl = userData?['logo_url'] as String?;
        final hasBusinessLogo = logoUrl != null && logoUrl.isNotEmpty;

        // Recovery for accounts where the DB trigger wrote is_pro=false
        // even though the user actually went through the entreprise flow
        // (Google sign-in didn't propagate is_pro metadata). If any
        // entreprise-only artefact exists, treat the account as pro and
        // self-heal the row so future logins are correct.
        final hasEntrepriseSignal =
            isProfileComplete || isBusinessInfoComplete || hasBusinessLogo;
        var isPro = isProRaw;
        if (!isPro && hasEntrepriseSignal) {
          isPro = true;
          unawaited(userRepository.setIsPro(user.id, true));
        }

        if (!isPro) {
          // CLIENT (Particulier) — always go to client home
          if (mounted) context.go('/client-home');
          return;
        }

        // ENTREPRISE — check onboarding completion. Either a real logo or
        // an explicit "skipped" flag is enough to bypass /business-info.
        if (!hasBusinessLogo && !isBusinessInfoComplete) {
          if (mounted) context.go('/business-info');
        } else if (!isProfileComplete) {
          if (mounted) context.go('/profession-selection');
        } else {
          if (mounted) context.go('/home');
        }
      } catch (e) {
        // Error fetching user data - go to business info to be safe
        if (mounted) context.go('/business-info');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        _attemptNavigation();
      }
    });

    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SvgPicture.asset(
              'assets/icons/LOGO.svg',
              width: responsive.width(42.7),
              height: responsive.width(42.7),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
