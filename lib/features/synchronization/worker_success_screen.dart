import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:koji/features/synchronization/worker_list_screen.dart'; // To reuse logic if needed, or simple nav

class WorkerSuccessScreen extends StatelessWidget {
  final Worker? worker; // Optional, to show details

  const WorkerSuccessScreen({super.key, this.worker});

  @override
  Widget build(BuildContext context) {
    // Defines context specific colors
    final darkBlue = const Color(0xFF0F3995);
    final primaryBlue = const Color(0xFF1D74FF);
    final scaffoldBg = const Color(0xFFF5F8FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                          color: primaryBlue.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "Profil Créé avec Succès!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                "Le nouveau collaborateur a été ajouté à votre base de données",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),

              // Worker Card Preview (Static for now or using passed worker)
              if (worker != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                       Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                          // image: ...
                        ),
                         child: const Icon(Icons.person, color: Colors.brown),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${worker!.firstName} ${worker!.lastName}",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          Text(
                            "${worker!.profession} - ${worker!.status}",
                            style: TextStyle(
                               fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[300]),
                    ],
                  ),
                ),

              const Spacer(),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                     // Navigate to assign project (Placeholder)
                     // context.go('/projects/assign', extra: worker);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Affectation - Coming Soon")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Affecter à un chantier", style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: Colors.white)
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                   onPressed: () {
                     // Go back to list, clearing stack up to home or list
                     context.go('/workers');
                   },
                   style: OutlinedButton.styleFrom(
                     backgroundColor: Colors.white,
                     side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.05),
                   ),
                   child: Text("Voir la liste des ouvriers", style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
