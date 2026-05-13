import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerDetailScreen extends StatelessWidget {
  final Worker worker;

  const WorkerDetailScreen({super.key, required this.worker});

  // Improved launch helper
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0F3995);
    final scaffoldBg = const Color(0xFFF5F8FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section (Blue Header)
            Container(
              padding: const EdgeInsets.only(
                  top: 60, bottom: 40, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F3995),
                    const Color(0xFF1652C9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(context, Icons.chevron_left,
                          onTap: () => context.pop()),
                      _buildHeaderButton(context, Icons.edit_outlined,
                          onTap: () {
                        // Navigate to Create Screen with worker data for editing
                        context.push('/workers/create', extra: worker);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Pic
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.amber[300],
                      borderRadius: BorderRadius.circular(20),
                      image: worker.profilePictureUrl != null
                          ? DecorationImage(
                              image: NetworkImage(worker.profilePictureUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                    ),
                    child: worker.profilePictureUrl == null
                        ? Icon(Icons.person,
                            size: 50, color: Theme.of(context).colorScheme.surface)
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "${worker.firstName} ${worker.lastName}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${worker.profession} - ${worker.status}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons (Call, Message, Email)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(context, Icons.phone, () {
                        if (worker.phoneNumber != null &&
                            worker.phoneNumber!.isNotEmpty) {
                          _makePhoneCall(worker.phoneNumber!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Pas de numéro de téléphone")));
                        }
                      }),
                      const SizedBox(width: 20),
                      _buildActionButton(context, Icons.chat_bubble_outline, () {
                        if (worker.phoneNumber != null &&
                            worker.phoneNumber!.isNotEmpty) {
                          _sendSms(worker.phoneNumber!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Pas de numéro de téléphone")));
                        }
                      }),
                      const SizedBox(width: 20),
                      _buildActionButton(context, Icons.email_outlined, () {
                        if (worker.email != null && worker.email!.isNotEmpty) {
                          _sendEmail(worker.email!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Pas d'email")));
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Title
                  _buildSectionTitle("Statistiques", trailing: "Ce mois"),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.access_time,
                          title: "164h",
                          subtitle: "Total Travaillé",
                          iconColor: darkBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.location_on,
                          title: "Villa Durand",
                          subtitle: "Chantier Actuel",
                          iconColor: darkBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle("Chantier"),

                  const SizedBox(height: 16),

                  // Project Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.04 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rénovation Appartement T3",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F3995),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Peinture & Finitions",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[300],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "65%",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F3995),
                              ),
                            ),
                            Text(
                              "8 jours restants",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[300],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(darkBlue),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle("Documents & Certifications"),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDocumentCard(
                          context,
                          icon: Icons.badge_outlined,
                          label: "Carte d'identité",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDocumentCard(
                          context,
                          icon: Icons.verified_outlined,
                          label: "Certifications",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Hire Date & Rate
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.04 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildRowInfo(
                            context,
                            Icons.calendar_month,
                            "Date d'embauche",
                            worker.hireDate != null
                                ? DateFormat('d MMMM yyyy')
                                    .format(worker.hireDate!)
                                : "12 Mars 2025"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.grey[100]),
                        ),
                        _buildRowInfo(
                            context,
                            Icons.payments_outlined,
                            "Taux Horaire",
                            worker.hourlyRate != null
                                ? "${worker.hourlyRate}€/H"
                                : "24.50€/H"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.grey[100]),
                        ),
                        // Phone and Email details visible in list
                        _buildRowInfo(context, Icons.phone, "Téléphone",
                            worker.phoneNumber ?? "Non renseigné"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.grey[100]),
                        ),
                        _buildRowInfo(context, Icons.email, "Email",
                            worker.email ?? "Non renseigné"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withAlpha((0.2 * 255).round()),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 20),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1D74FF), size: 24),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3995),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.04 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3995),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.02 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF0F3995)),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowInfo(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3995), // Dark blue bg for icon
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3995),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}
