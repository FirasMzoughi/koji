import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  void _handleLogin() async {
    if (!_isFormValid) return;
    setState(() => _loginAttempted = true);
    await ref.read(authProvider.notifier).signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _handleGoogleLogin() async {
    final isPro = ref.read(accountTypeProvider) ?? false;
    setState(() => _loginAttempted = true);
    await ref.read(authProvider.notifier).signInWithGoogle(isPro: isPro);
  }

  // True only after the user taps the login button on THIS screen
  bool _loginAttempted = false; // ignore: prefer_final_fields
  bool _isNavigating = false;

  Future<void> _navigateAfterLogin(user) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final userData = await userRepo.getUser(user.id);
      if (!mounted) return;
      final isComplete = userData?['is_profile_complete'] == true;
      context.go(isComplete ? '/home' : '/profession-selection');
    } catch (_) {
      if (mounted) context.go('/profession-selection');
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          // Only navigate if the user actively logged in from THIS screen
          if (user != null && _loginAttempted) {
            _navigateAfterLogin(user);
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${error.toString()}')),
          );
        },
      );
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.paddingSymmetric(horizontalPercent: 6.4), // ~24px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.height(5)), // ~40px

              // Logo
              Center(
                child: Text(
                  'K Ô J I',
                  style: TextStyle(
                    fontSize: responsive.fontSize(28),
                    fontWeight: FontWeight.bold,
                    letterSpacing: responsive.width(1.6), // ~6px
                    color: AppTheme.darkNavy,
                  ),
                ),
              ),

              SizedBox(height: responsive.height(5)), // ~40px

              // Title
              Text(
                'Bon retour ! Accédez à vos devis et chantiers en un instant',
                style: AppTheme.headingStyle(context).copyWith(
                  fontSize: responsive.fontSize(24),
                ),
                textAlign: TextAlign.left,
              ),

              SizedBox(height: responsive.height(4)), // ~32px

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Adresse e-mail',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: responsive.height(2)), // ~16px

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textLight,
                    size: responsive.iconSize(20),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              SizedBox(height: responsive.height(2)), // ~16px

              // Remember Me & Forgot Password
              Row(
                children: [
                  SizedBox(
                    width: responsive.iconSize(20),
                    height: responsive.iconSize(20),
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      activeColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            responsive.borderRadius(4)),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.width(2.1)),
                  Text(
                    'Se souvenir',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppTheme.textLight,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Mot de passe oublié?',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.height(3)), // ~24px

              // Login Button
              ElevatedButton(
                onPressed: _isFormValid && !isLoading ? _handleLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? AppTheme.darkNavy
                      : const Color(0xFFE5E7EB),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      vertical: responsive.height(2.25)), // ~18px
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius(12)),
                  ),
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFFD1D5DB),
                ),
                child: isLoading
                    ? SizedBox(
                        height: responsive.iconSize(20),
                        width: responsive.iconSize(20),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              SizedBox(height: responsive.height(3)), // ~24px

              // "Ou" divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: responsive.width(4.3)), // ~16px
                    child: Text(
                      'Ou',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: responsive.fontSize(14),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),

              SizedBox(height: responsive.height(3)), // ~24px

              // Google Sign-in Button
              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleGoogleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      vertical: responsive.height(2)), // ~16px
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius(12)),
                  ),
                ),
                icon: Container(
                  padding: EdgeInsets.all(responsive.width(0.5)), // ~2px
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius(4)),
                  ),
                  child: Icon(Icons.g_mobiledata,
                      color: AppTheme.primaryBlue,
                      size: responsive.iconSize(20)),
                ),
                label: Text(
                  'Continuer avec Google',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: responsive.height(3)), // ~24px

              // Signup Link
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppTheme.textLight,
                      ),
                      children: [
                        const TextSpan(text: 'Pas encore de compte ? '),
                        TextSpan(
                          text: 'S\'inscrire',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: responsive.height(5)), // ~40px
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    final responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: responsive.fontSize(16),
          color: AppTheme.darkNavy,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontSize: responsive.fontSize(16),
            color: AppTheme.textLight,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.width(4.3), // ~16px
            vertical: responsive.height(2), // ~16px
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
