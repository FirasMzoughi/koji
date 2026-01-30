import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignatureSuccessScreen extends StatelessWidget {
  const SignatureSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Détails de Devis', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF0F2648))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F2648), size: 20),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                   // Circle Check
                   Container(
                     width: 100, height: 100,
                     decoration: const BoxDecoration(
                       shape: BoxShape.circle,
                       color: Color(0xFFECFDF5), // Light green
                     ),
                     child: Stack(
                       alignment: Alignment.center,
                       children: [
                          const Icon(Icons.check_circle, size: 60, color: Color(0xFF10B981)),
                          Positioned(
                             right: 10, bottom: 5,
                             child: Container(
                               padding: const EdgeInsets.all(4),
                               decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                               child: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF94A3B8)),
                             ),
                          )
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   const Text("Devis prêt !", style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2648))),
                   const SizedBox(height: 8),
                   const Text(
                     "Le devis #D-2405 a été signé avec succès.",
                     textAlign: TextAlign.center,
                     style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B), fontSize: 14),
                   ),
                   const SizedBox(height: 24),
                   
                   // Progress Bar
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text("PROGRESSION", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF94A3B8))),
                        Text("100%", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF10B981))),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Container(
                     height: 8,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color: const Color(0xFFE2E8F0),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: FractionallySizedBox(
                       alignment: Alignment.centerLeft,
                       widthFactor: 1.0,
                       child: Container(
                         decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                       ),
                     ),
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // PDF Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Devis_Final_D-2405.pdf", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF0F2648))),
                        Text("1.2 MB • PDF Document", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  IconButton(
                     icon: const Icon(Icons.visibility_outlined, color: Color(0xFF94A3B8)),
                     onPressed: () {},
                  )
                ],
              ),
            ),
            
            const Spacer(),
            
            // Actions
             _buildBtn(Icons.visibility_outlined, "Ouvrir le PDF", const Color(0xFF1E3A8A), Colors.white),
             const SizedBox(height: 12),
             _buildBtn(Icons.download_outlined, "Télécharger sur l'appareil", const Color(0xFF1E3A8A), Colors.white),
             const SizedBox(height: 20),
             
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.share, color: Color(0xFF94A3B8), size: 18),
                 const SizedBox(width: 8),
                 Text("Partager le PDF", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: const Color(0xFF64748B).withOpacity(0.8))),
               ],
             ),
             
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color bg, Color fg) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
