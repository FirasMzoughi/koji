import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChantierDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ChantierDashboardScreen({super.key, required this.data});

  @override
  State<ChantierDashboardScreen> createState() =>
      _ChantierDashboardScreenState();
}

class _ChantierDashboardScreenState extends State<ChantierDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background subtle peach gradient at the top right
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFADBCE).withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFADBCE).withOpacity(0.5),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProjectInfoCard(),
                        const SizedBox(height: 16),
                        _buildTabToggles(),
                        const SizedBox(height: 24),
                        
                        if (_selectedTab == 0) ...[
                          _buildAgendaSection(),
                          const SizedBox(height: 16),
                          _buildDevisPDFSection(),
                          const SizedBox(height: 16),
                          _buildTasksSection(),
                          const SizedBox(height: 16),
                          _buildOuvrierSection(),
                          const SizedBox(height: 16),
                          _buildFournituresSection(),
                          const SizedBox(height: 16),
                          _buildSuiviChantierSection(),
                          const SizedBox(height: 16),
                          _buildObservationBox(),
                        ] else ...[
                          _buildFinDeChantierSection(),
                        ],

                        const SizedBox(height: 100), // Bottom padding for FAB/Validation button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Validation Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 30, // Above bottom nav if any, or general safe area
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedTab == 0 ? 'Valider la tâche' : 'Clôturer et Archiver le Projet',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _selectedTab == 0 ? Icons.check_circle_outline : Icons.archive_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF0F172A),
              size: 28,
            ),
          ),
          const Text(
            'Suivie chantier',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Red dot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sous sol - Carla Balti',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#DEV-2026-120',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.info_outline,
            color: Color(0xFF0F172A),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Détails',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                      color: _selectedTab == 0 ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Taches chantier',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                      color: _selectedTab == 1 ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, String? actionText, VoidCallback? onAction}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                const Icon(Icons.edit, size: 14, color: Color(0xFF3B82F6)),
                const SizedBox(width: 4),
                Text(
                  actionText,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAgendaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Agenda', icon: Icons.calendar_today_outlined, actionText: 'Modifier'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDateColumn('Date De Début', '12 Oct. 2026'),
                        _buildDateColumn('Date De Fin', '15 Dec. 2026'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    const Text(
                      'Plage Horaire',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '08:00 — 17:00',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '(8h prévues)',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEB), // Light pink
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 14,
                        child: Container(
                          width: 40,
                          height: 6,
                          color: const Color(0xFF0F172A).withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ],
    );
  }

  Widget _buildDevisPDFSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), // Red tint
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Devis_Final_D-2405.pdf',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1.2 MB • PDF Document',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      children: [
        _buildTaskItem('Dépoussiérage', true),
        const SizedBox(height: 12),
        _buildTaskItem('Ponçage des surfaces', true),
        const SizedBox(height: 12),
        
        // Expandable task group
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Theme(
            data: ThemeData().copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              iconColor: const Color(0xFF0F172A),
              collapsedIconColor: const Color(0xFF0F172A),
              title: Row(
                children: [
                  const Text(
                    'Préparation des murs et plafonds',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'En cours',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Début',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Row(
                            children: const [
                              Text(
                                '01 Mar. 2026',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fin',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Row(
                            children: const [
                              Text(
                                '09 Mar. 2026',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(String title, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF0F172A) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: isCompleted ? Colors.white : Colors.transparent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Terminé',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildOuvrierSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildSectionHeader('Ouvrier/ sous-traitant', icon: Icons.people_outline)),
              const Text(
                'Pointage',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOuvrierCard('Jean-Marc', 'Chef de chantier', 'PRÉSENT', true,
              Colors.brown[300]!, const Color(0xFF059669)),
          const SizedBox(height: 12),
          _buildOuvrierCard('Julien Dubois', 'Plâtrier', 'ABSENT', false,
              Colors.amber[700]!, const Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Besoin d\'un remplaçant ?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.person_add_alt_1_outlined, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 4),
                  Text(
                    'REMPLACER',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildSubContractorCard(),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
              label: const Text(
                'Ajouter Ouvrier',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOuvrierCard(String name, String role, String status, bool present, Color avatarColor, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withOpacity(0.2),
                child: Icon(Icons.person, color: avatarColor),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: present ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    decoration: present ? TextDecoration.none : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 14, color: statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubContractorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PlacoExpert SARL',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '2/2 présents',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildFournituresSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Ajout fournitures', icon: Icons.local_shipping_outlined),
          const SizedBox(height: 16),
          _buildFournitureItem('Plaques BA13 Standard', '45 unités', 'LIVRÉ', true),
          const Divider(color: Color(0xFFF1F5F9)),
          _buildFournitureItem('Rails R48 (3m)', '20 unités', 'EN ATTENTE', false),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
              label: const Text(
                'Ajouter un matériel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFournitureItem(String name, String qty, String status, bool delivered) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Quantité: $qty',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: delivered ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: delivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                delivered ? Icons.check_circle_outline : Icons.access_time,
                color: delivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuiviChantierSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildSectionHeader('Suivi de Chantier', icon: Icons.camera_alt_outlined)),
              const Text(
                '3 photos',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPhotoThumbnail(Colors.blue[200]!),
                const SizedBox(width: 12),
                _buildPhotoThumbnail(Colors.blueGrey[800]!),
                const SizedBox(width: 12),
                _buildPhotoThumbnail(Colors.cyan[100]!),
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                      style: BorderStyle.solid, // Flutter doesn't support dashed easily without custom painter, using solid for now.
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo_outlined, color: Color(0xFF3B82F6), size: 20),
                      SizedBox(height: 4),
                      Text(
                        'AJOUTER',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(Color color) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1541888081622-3a5b98a3b5c3?q=80&w=2670&auto=format&fit=crop'), // Placeholder construction image
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildObservationBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const TextField(
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Ajouter une observation pour ce chantier...',
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFinDeChantierSection() {
    // This represents the final state from image 4
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progression
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Progression Totale',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '100% Terminée',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 8,
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '48/48 étapes validées par le conducteur de travaux',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        const Text(
          'Résumé Des Validations',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        _buildValidationRow('Gros œuvre & Fondations'),
        const SizedBox(height: 12),
        _buildValidationRow('Second œuvre & Équipements'),
        const SizedBox(height: 12),
        _buildValidationRow('Finitions et Nettoyage final'),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF94A3B8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '142 photos haute résolution jointes au dossier d\'archivage.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Visite De Réception Client',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Observations Finales',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Entrez d\'éventuelles réserves ou commentaires du client...',
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
             Text(
              'Signature du Client',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
             Text(
              'Effacer',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              style: BorderStyle.solid, // Custom painter needed for dashed natively
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.draw_outlined, color: Color(0xFFCBD5E1), size: 32),
                SizedBox(height: 8),
                Text(
                  'Signez Ici Pour Valider La Réception Du Chantier',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                     Text(
                      'Information d\'Archivage',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Une fois le chantier clôturé, toutes les données (photos, devis, factures, signatures) seront déplacées vers vos archives sécurisées.\n\nElles resteront consultables en lecture seule à tout moment.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidationRow(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
