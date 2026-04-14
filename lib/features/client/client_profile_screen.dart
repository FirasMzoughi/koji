import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/auth_repository.dart' show authRepositoryProvider;
import 'package:koji/features/auth/repository/user_repository.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  static const _darkNavy = Color(0xFF0F172A);
  static const _blue = Color(0xFF1D74FF);
  static const _slate = Color(0xFF64748B);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _editMode = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      final data = await ref.read(userRepositoryProvider).getUser(user.id);
      if (mounted) {
        setState(() {
          _email = user.email ?? '';
          _nameCtrl.text = (data?['full_name'] as String?) ?? '';
          _phoneCtrl.text = (data?['phone'] as String?) ?? '';
          _addressCtrl.text = (data?['address'] as String?) ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateClientProfile(
            uid: user.id,
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      if (mounted) {
        setState(() { _saving = false; _editMode = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Avatar + name ──
                  SliverToBoxAdapter(child: _buildAvatarSection()),

                  // ── Form ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes informations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _darkNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            label: 'Nom complet',
                            controller: _nameCtrl,
                            icon: Icons.person_outline,
                            enabled: _editMode,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            label: 'Email',
                            value: _email ?? '',
                            icon: Icons.email_outlined,
                            enabled: false,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            label: 'Téléphone',
                            controller: _phoneCtrl,
                            icon: Icons.phone_outlined,
                            enabled: _editMode,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            label: 'Adresse',
                            controller: _addressCtrl,
                            icon: Icons.location_on_outlined,
                            enabled: _editMode,
                          ),
                          const SizedBox(height: 24),

                          // Save / Edit button
                          if (_editMode)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Enregistrer',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Options ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paramètres',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _darkNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _optionTile(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            color: _blue,
                            onTap: () {},
                          ),
                          _optionTile(
                            icon: Icons.security_outlined,
                            label: 'Sécurité & mot de passe',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {},
                          ),
                          _optionTile(
                            icon: Icons.help_outline,
                            label: 'Aide & support',
                            color: const Color(0xFF10B981),
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _optionTile(
                            icon: Icons.logout_rounded,
                            label: 'Déconnexion',
                            color: Colors.red,
                            onTap: _signOut,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        children: [
          const Text(
            'Mon Compte',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _editMode = !_editMode),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _editMode
                    ? Colors.red.withValues(alpha: 0.1)
                    : _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _editMode ? Icons.close : Icons.edit_outlined,
                    size: 14,
                    color: _editMode ? Colors.red : _blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _editMode ? 'Annuler' : 'Modifier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _editMode ? Colors.red : _blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : (_email?.isNotEmpty == true ? _email![0].toUpperCase() : 'C');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                  color: _blue.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text
                      : 'Mon profil',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email ?? '',
                  style: const TextStyle(fontSize: 13, color: _slate),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Compte Particulier',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    TextEditingController? controller,
    String? value,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? const Color(0xFFCBD5E1)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller ?? TextEditingController(text: value),
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? _darkNavy : _slate,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _slate),
          prefixIcon: Icon(icon, color: _slate, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : _darkNavy,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: isDestructive ? Colors.red : _slate),
          ],
        ),
      ),
    );
  }
}
