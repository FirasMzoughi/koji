import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/providers/account_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountType = ref.watch(accountTypeProvider);
    final isIndividual = accountType == AccountType.individual;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isIndividual)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Mode Particulier',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Icon(
                    Icons.format_paint_outlined,
                    size: 80,
                    color: Color(0xFF1A237E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Koji',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'outil des maîtres artisans',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Form Fields
                  TextFormField(
                    initialValue: 'artisan@koji.app',
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: 'password',
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (accountType == AccountType.pro) {
                         context.go('/pro/domain-selection');
                      } else {
                         context.go('/dashboard');
                      }
                    },
                    child: const Text('Se connecter'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider with "OU"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Google Sign In
                      debugPrint('Google Sign In pressed');
                      if (accountType == AccountType.pro) {
                         context.go('/pro/domain-selection');
                      } else {
                         context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continuer avec Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Apple Sign In Button
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Apple Sign In
                      debugPrint('Apple Sign In pressed');
                      if (accountType == AccountType.pro) {
                         context.go('/pro/domain-selection');
                      } else {
                         context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Continuer avec Apple'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/signup');
                        },
                        child: const Text('S\'inscrire'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextButton(
                    onPressed: () {},
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
