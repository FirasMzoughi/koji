import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/chantier_client_screen.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// 'entreprise', 'particulier', or null (existing user — route by DB value)
  final String? loginType;

  const LoginScreen({super.key, this.loginType});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Particulier code-login (Identifiant + Mot de passe per chantier).
  final _codeController = TextEditingController();
  final _codePasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _codeLoginLoading = false;

  /// True for the "Espace Particulier" — that login is a per-chantier
  /// Identifiant + Mot de passe (no email / Google / signup).
  bool get _isParticulier => widget.loginType == 'particulier';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _codePasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  bool get _isCodeFormValid =>
      _codeController.text.trim().isNotEmpty &&
      _codePasswordController.text.isNotEmpty;

  /// Verify the chantier Identifiant + Mot de passe, then open the in-app
  /// chantier space (Devis / Suivi / Messages) for that devis. No Supabase
  /// session is created — the screen loads everything by the quote id.
  Future<void> _handleParticulierLogin() async {
    if (!_isCodeFormValid || _codeLoginLoading) return;
    setState(() => _codeLoginLoading = true);
    try {
      final quoteId = await ref.read(authRepositoryProvider).loginWithAccessCode(
            code: _codeController.text,
            password: _codePasswordController.text,
          );
      if (!mounted) return;

      if (quoteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identifiant ou mot de passe incorrect.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChantierClientScreen(quoteId: quoteId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _codeLoginLoading = false);
    }
  }

  void _handleLogin() async {
    if (!_isFormValid) return;
    setState(() => _loginAttempted = true);
    await ref.read(authProvider.notifier).signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _handleForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Mot de passe oublié',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saisissez votre adresse e-mail. Vous recevrez un lien pour réinitialiser votre mot de passe.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.email_outlined,
                        size: 20, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setDs(() => sending = true);
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .resetPassword(email: email);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'E-mail envoyé ! Vérifiez votre boîte de réception.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDs(() => sending = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authErrorMessage(e)),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.surface,
                          strokeWidth: 2),
                    )
                  : Text('Envoyer',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.surface)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin() async {
    // Honour the URL-param loginType first (?type=entreprise|particulier).
    // Without this, a brand-new Google user gets is_pro=false written to the
    // DB even when they came in via /login?type=entreprise, and the next
    // cold start routes them to /client-home.
    final loginType = widget.loginType;
    final bool isPro;
    if (loginType == 'entreprise') {
      isPro = true;
    } else if (loginType == 'particulier') {
      isPro = false;
    } else {
      isPro = ref.read(accountTypeProvider) ?? false;
    }
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

      // If loginType is specified, respect the user's chosen interface.
      // Otherwise fall back to what is stored in the DB.
      final loginType = widget.loginType;
      final bool isPro;
      if (loginType == 'entreprise') {
        isPro = true;
      } else if (loginType == 'particulier') {
        isPro = false;
      } else {
        // No type param — route by the value stored in DB.
        // Default false (particulier) if field is missing so we don't
        // accidentally send a non-pro user to the enterprise home.
        isPro = userData?['is_pro'] as bool? ?? false;
      }

      // CLIENT — go straight to client home
      if (!isPro) {
        context.go('/client-home');
        return;
      }

      // ENTREPRISE — check onboarding completion
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
            SnackBar(content: Text(authErrorMessage(error))),
          );
        },
      );
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.paddingSymmetric(horizontalPercent: 6.4), // ~24px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.height(1.5)),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/account-type'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppTheme.darkNavy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              SizedBox(height: responsive.height(2)),

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

              SizedBox(height: responsive.height(2)),

              // Account-type badge
              if (widget.loginType != null)
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.width(4),
                      vertical: responsive.height(0.75),
                    ),
                    decoration: BoxDecoration(
                      color: widget.loginType == 'entreprise'
                          ? AppTheme.darkNavy
                          : AppTheme.primaryBlue,
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.loginType == 'entreprise'
                              ? Icons.business
                              : Icons.person,
                          color: Theme.of(context).colorScheme.surface,
                          size: responsive.iconSize(16),
                        ),
                        SizedBox(width: responsive.width(1.5)),
                        Text(
                          widget.loginType == 'entreprise'
                              ? 'Espace Entreprise'
                              : 'Espace Particulier',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: responsive.fontSize(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: responsive.height(3)), // ~24px

              // Title
              Text(
                widget.loginType == 'particulier'
                    ? 'Bon retour ! Suivez vos travaux et devis en un instant'
                    : 'Bon retour ! Accédez à vos devis et chantiers en un instant',
                style: AppTheme.headingStyle(context).copyWith(
                  fontSize: responsive.fontSize(24),
                ),
                textAlign: TextAlign.left,
              ),

              SizedBox(height: responsive.height(4)), // ~32px

              // ── Espace Particulier : Identifiant + Mot de passe (per chantier).
              //    No email / Google / signup — the client receives these
              //    credentials by message from the entreprise.
              if (_isParticulier) ...[
                _buildTextField(
                  controller: _codeController,
                  label: 'Identifiant',
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: responsive.height(2)),
                _buildTextField(
                  controller: _codePasswordController,
                  label: 'Mot de passe',
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textLight,
                      size: responsive.iconSize(20),
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                SizedBox(height: responsive.height(3)),
                ElevatedButton(
                  onPressed: _isCodeFormValid && !_codeLoginLoading
                      ? _handleParticulierLogin
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCodeFormValid
                        ? AppTheme.darkNavy
                        : const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: responsive.height(2.25)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius(12)),
                    ),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFFD1D5DB),
                  ),
                  child: _codeLoginLoading
                      ? SizedBox(
                          height: responsive.iconSize(20),
                          width: responsive.iconSize(20),
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.surface,
                              strokeWidth: 2))
                      : Text(
                          'Accéder à mon devis',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(height: responsive.height(2)),
                Text(
                  'Saisissez l’identifiant et le mot de passe reçus par message de votre artisan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppTheme.textLight,
                  ),
                ),
              ] else ...[
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
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius(4)),
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
                    onTap: _handleForgotPassword,
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
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.surface,
                            strokeWidth: 2))
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
                    color: Theme.of(context).colorScheme.surface,
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
                  onTap: () {
                    final t = widget.loginType;
                    context.go(t != null ? '/signup?type=$t' : '/signup');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppTheme.textLight,
                      ),
                      children: const [
                        TextSpan(text: 'Pas encore de compte ? '),
                        TextSpan(
                          text: 'S\'inscrire',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ], // end else (entreprise email/Google login)

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
