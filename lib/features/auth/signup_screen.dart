import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';
import 'package:koji/core/responsive_helper.dart';

class SignupScreen extends ConsumerStatefulWidget {
  /// 'entreprise', 'particulier', or null
  final String? signupType;

  const SignupScreen({super.key, this.signupType});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _marketingConsent = true;
  bool _termsAccepted = true;
  String _selectedCountry = 'France';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _termsAccepted;
  }

  bool _awaitingEmailConfirmation = false;

  void _handleSignup() async {
    if (!_isFormValid) return;

    // Derive isPro from the signupType param; fall back to accountTypeProvider
    final isPro = widget.signupType == 'entreprise'
        ? true
        : widget.signupType == 'particulier'
            ? false
            : ref.read(accountTypeProvider) ?? false;

    // Set the flag BEFORE awaiting so ref.listen is blocked from the start
    setState(() => _awaitingEmailConfirmation = true);

    final needsConfirmation = await ref.read(authProvider.notifier).signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          isPro: isPro,
        );

    if (needsConfirmation && mounted) {
      final email = _emailController.text.trim();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Vérifiez votre e-mail',
            style: AppTheme.headingStyle(context).copyWith(fontSize: 20),
          ),
          content: Text(
            'Un e-mail de confirmation a été envoyé à $email. Veuillez cliquer sur le lien pour activer votre compte.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'J\'ai compris',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _awaitingEmailConfirmation = false);
        context.go('/login');
      }
    } else {
      // No confirmation needed (auto-login) — unblock the listener
      if (mounted) setState(() => _awaitingEmailConfirmation = false);
    }
  }

  void _handleGoogleSignup() async {
    final isPro = widget.signupType == 'entreprise'
        ? true
        : widget.signupType == 'particulier'
            ? false
            : ref.read(accountTypeProvider) ?? false;

    await ref.read(authProvider.notifier).signInWithGoogle(isPro: isPro);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (user) {
          // Don't navigate if we're about to show (or are showing) the email
          // confirmation dialog — the dialog's own callback handles routing.
          if (_awaitingEmailConfirmation) return;
          if (user != null && previous?.value == null) {
            // User just signed up and was immediately confirmed (no email
            // verification required), go to profession selection.
            context.go('/profession-selection');
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkNavy),
          onPressed: () {
            final t = widget.signupType;
            context.go(t != null ? '/login?type=$t' : '/login');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.paddingSymmetric(horizontalPercent: 6.4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Logo
                Center(
                  child: Text(
                    'K Ô J I',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Account-type badge
                if (widget.signupType != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.signupType == 'entreprise'
                            ? AppTheme.darkNavy
                            : AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.signupType == 'entreprise'
                                ? Icons.business
                                : Icons.person,
                            color: Theme.of(context).colorScheme.surface,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.signupType == 'entreprise'
                                ? 'Espace Entreprise'
                                : 'Espace Particulier',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Title
                Text(
                  widget.signupType == 'particulier'
                      ? 'Inscrivez-vous pour suivre vos travaux et devis'
                      : 'Inscrivez-vous pour simplifier votre activité',
                  style: AppTheme.headingStyle(context).copyWith(fontSize: 24),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 24),

                // Google Sign-in Button
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.g_mobiledata,
                        color: AppTheme.primaryBlue, size: 20),
                  ),
                  label: Text(
                    'Continuer avec Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // "Ou" divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Ou',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),

                const SizedBox(height: 24),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mot de passe (min. 8 caractères)',
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textLight,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Country Dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppTheme.darkNavy),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.darkNavy,
                      ),
                      items: ['France', 'Tunisie', 'Maroc', 'Algérie']
                          .map((country) => DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Marketing Consent Checkbox
                _buildCheckbox(
                  value: _marketingConsent,
                  text:
                      'Envoyez-moi des conseils pour optimiser la gestion de mes devis et chantiers.',
                  onChanged: (value) {
                    setState(() {
                      _marketingConsent = value!;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            _termsAccepted = value!;
                          });
                        },
                        activeColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Oui, je comprends et j\'accepte les '),
                            TextSpan(
                              text: 'Conditions d\'utilisation',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' et la '),
                            TextSpan(
                              text: 'Politique de confidentialité',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' de Kôji.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(true),
                    const SizedBox(width: 8),
                    _buildDot(false),
                    const SizedBox(width: 8),
                    _buildDot(false),
                  ],
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isFormValid && !isLoading ? _handleSignup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? AppTheme.darkNavy
                        : const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFFD1D5DB),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Suivant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isFormValid) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ],
                        ),
                ),

                const SizedBox(height: 20),

                // Login Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final t = widget.signupType;
                      context.go(t != null ? '/login?type=$t' : '/login');
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                        children: [
                          const TextSpan(text: 'Déjà inscrit ? '),
                          TextSpan(
                            text: 'Se connecter',
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

                const SizedBox(height: 32),
              ],
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.darkNavy,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 16,
            color: AppTheme.textLight,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String text,
    required Function(bool?) onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.darkNavy : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
