import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';
import 'package:koji/core/responsive_helper.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

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

  void _handleSignup() async {
    if (!_isFormValid) return;

    // Get isPro from provider (default to false if not set)
    final isPro = ref.read(accountTypeProvider) ?? false;

    await ref.read(authProvider.notifier).signUpWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
      isPro: isPro,
    );
  }

  void _handleGoogleSignup() async {
    // Get isPro from provider (default to false if not set)
    final isPro = ref.read(accountTypeProvider) ?? false;
    
    await ref.read(authProvider.notifier).signInWithGoogle(isPro: isPro);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null && previous?.value == null) {
            // User just signed up successfully, go to profession selection
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkNavy),
          onPressed: () => context.pop(),
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
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Inscrivez-vous pour simplifier votre activité',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.g_mobiledata, color: AppTheme.primaryBlue, size: 20),
                  ),
                  label: Text(
                    'Continuer avec Google',
                    style: TextStyle(fontFamily: 'Outfit', 
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
                        style: TextStyle(fontFamily: 'Outfit', 
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
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.darkNavy),
                      style: TextStyle(fontFamily: 'Outfit', 
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
                  text: 'Envoyez-moi des conseils pour optimiser la gestion de mes devis et chantiers.',
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
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 13,
                            color: AppTheme.textLight,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'Oui, je comprends et j\'accepte les '),
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
                  onPressed: _isFormValid && !isLoading
                      ? _handleSignup
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? AppTheme.darkNavy : const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFFD1D5DB),
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Suivant',
                        style: TextStyle(fontFamily: 'Outfit', 
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
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontFamily: 'Outfit', 
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
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 16,
          color: AppTheme.darkNavy,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontFamily: 'Outfit', 
            fontSize: 16,
            color: AppTheme.textLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            style: TextStyle(fontFamily: 'Outfit', 
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
