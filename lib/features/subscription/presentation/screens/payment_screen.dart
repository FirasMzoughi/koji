import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Détails de la carte',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom sur la carte',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Numéro de carte',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                    hintText: '0000 0000 0000 0000',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date exp.',
                          prefixIcon: Icon(Icons.date_range),
                          border: OutlineInputBorder(),
                          hintText: 'MM/AA',
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'CVC',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          hintText: '123',
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                         validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isProcessing = true;
                        });
                        
                        // Mock delay
                        await Future.delayed(const Duration(seconds: 2));
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Votre abonnement est actif. Merci !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Go back to dashboard (pop twice: subscription -> payment -> dashboard)
                           // Or go directly to dashboard if we want to reset stack
                          context.go('/dashboard'); 
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Valider le paiement'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
