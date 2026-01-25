import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

/// Home screen header with gradient background
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    final user = ref.read(authProvider).value;
    if (user != null) {
      final userData = await ref.read(userRepositoryProvider).getUser(user.id);
      final logoUrl = userData?['logo_url'] as String?;
      if (mounted && logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // We remove the theme toggle to match the image exactly.
    // The background is handled by the parent container in HomeScreen, 
    // but the text colors need to be white.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with icons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu icon (Custom stack to match image strokes)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2.5,
                    width: 26,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                    margin: const EdgeInsets.only(bottom: 5),
                  ),
                  Container(
                    height: 2.5,
                    width: 18,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                    margin: const EdgeInsets.only(bottom: 5),
                  ),
                  Container(
                    height: 2.5,
                    width: 26,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
              // Right side icons
              Row(
                children: [
                  const Icon(Icons.translate, color: Colors.white, size: 26),
                  const SizedBox(width: 20),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF453A), // Red notification dot
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: _logoUrl != null
                        ? NetworkImage(_logoUrl!) as ImageProvider
                        : null,
                    backgroundColor: Colors.white,
                    child: _logoUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF0F3995)) // Blue icon if no image
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Welcome text
        Padding(
          padding: responsive.paddingSymmetric(horizontalPercent: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenue sur Kôji !',
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre bureau\nmobile est prêt !',
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 34, 
                  color: Colors.white,
                  fontWeight: FontWeight.w800, // Extra bold
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
