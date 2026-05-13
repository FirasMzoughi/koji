import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/features/quote/repository/task_repository.dart';
import 'package:koji/features/pricing/repository/pricing_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String profession;
  final String? parentId;
  final String? parentCode;

  const CreateTaskScreen({
    super.key,
    required this.profession,
    this.parentId,
    this.parentCode,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _designationController = TextEditingController();
  final _quantiteController    = TextEditingController();
  final _commentaireController = TextEditingController();
  final _mainOeuvreController  = TextEditingController();
  final _fournituresController = TextEditingController();

  String _selectedUnite = 'm²';
  bool   _isSaving      = false;

  // Toggle: show main d'oeuvre / fournitures in devis
  bool _showMainOeuvre  = true;
  bool _showFournitures = true;

  // Photo / pièce jointe
  final List<File> _attachments = [];

  double _tauxHoraire = 56.25;

  static const List<String> _unites = ['m²', 'ml', 'u', 'h', 'forfait', 'ens', 'kg', 'L'];

  @override
  void initState() {
    super.initState();
    _loadTauxHoraire();
  }

  @override
  void dispose() {
    _designationController.dispose();
    _quantiteController.dispose();
    _commentaireController.dispose();
    _mainOeuvreController.dispose();
    _fournituresController.dispose();
    super.dispose();
  }

  Future<void> _loadTauxHoraire() async {
    try {
      if (widget.profession.isNotEmpty) {
        final profile = await ref
            .read(pricingRepositoryProvider)
            .getProfileForProfession(widget.profession);
        if (profile != null && profile.hoursPerDay > 0) {
          if (mounted) setState(() => _tauxHoraire = profile.hourlyRate);
          return;
        }
      }
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;
      final userData = await ref.read(userRepositoryProvider).getUser(user.id);
      final biz = userData?['business_info'] as Map<String, dynamic>?;
      if (biz != null) {
        final daily = (biz['dailyRate'] as num?)?.toDouble() ?? 450.0;
        final hours = (biz['hoursPerDay'] as num?)?.toDouble() ?? 8.0;
        if (mounted) setState(() => _tauxHoraire = hours > 0 ? daily / hours : 56.25);
      }
    } catch (_) {}
  }

  bool get _isSubTask => widget.parentId != null;

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E65F3)),
                title: const Text('Prendre une photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2E65F3)),
                title: const Text('Choisir depuis la galerie',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _attachments.add(File(picked.path)));
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {

      await ref.read(taskRepositoryProvider).createTask(
        title:       _designationController.text.trim(),
        description: _commentaireController.text.trim().isNotEmpty
            ? _commentaireController.text.trim()
            : null,
        profession:  widget.profession,
        unite:       _selectedUnite,
        parentId:    widget.parentId,
        typePoste:   _isSubTask ? 'SOUS-POSTE' : 'POSTE',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isSubTask ? 'Nouveau sous-poste' : 'Nouvel ouvrage',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            // ── Sub-task parent indicator ─────────────────────────────
            if (_isSubTask) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree, size: 16, color: Color(0xFF0369A1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sous-poste de ${widget.parentCode ?? "parent"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── DÉSIGNATION ──────────────────────────────────────────
            _sectionLabel('Désignation *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _designationController,
              hint: 'ex: Pose carrelage sol ≤ 60×60 cm',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Désignation requise' : null,
            ),

            const SizedBox(height: 18),

            // ── UNITÉ ────────────────────────────────────────────────
            _sectionLabel('Unité *'),
            const SizedBox(height: 6),
            _buildDropdownRow(
              value: _selectedUnite,
              items: _unites,
              onChanged: (v) => setState(() => _selectedUnite = v!),
            ),

            const SizedBox(height: 18),

            // ── QUANTITÉ ─────────────────────────────────────────────
            _sectionLabel('Quantité'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _quantiteController,
              hint: 'ex: 25',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 24),

            // ── Divider ──────────────────────────────────────────────
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // ── COMMENTAIRE + PHOTO ──────────────────────────────────
            _sectionLabel('Commentaire'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _commentaireController,
              hint: 'Ajouter un commentaire...',
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            // Photo / pièce jointe
            _sectionLabel('Photo / Pièce jointe'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._attachments.asMap().entries.map((entry) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        entry.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _attachments.removeAt(entry.key)),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
                GestureDetector(
                  onTap: _pickAttachment,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE), style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF3B82F6), size: 24),
                        SizedBox(height: 4),
                        Text('Ajouter', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Divider ──────────────────────────────────────────────
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // ── MAIN D'OEUVRE ────────────────────────────────────────
            _buildToggleSection(
              label: "Main d'œuvre",
              icon: Icons.engineering_outlined,
              color: const Color(0xFF0369A1),
              isEnabled: _showMainOeuvre,
              onToggle: (v) => setState(() => _showMainOeuvre = v),
              child: _showMainOeuvre
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildTextField(
                        controller: _mainOeuvreController,
                        hint: 'Montant en € (ex: 350)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 14),

            // ── FOURNITURES ──────────────────────────────────────────
            _buildToggleSection(
              label: 'Fournitures',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFFB45309),
              isEnabled: _showFournitures,
              onToggle: (v) => setState(() => _showFournitures = v),
              child: _showFournitures
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildTextField(
                        controller: _fournituresController,
                        hint: 'Montant en € (ex: 120)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 10),
            // Hint about toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Activez ou désactivez pour afficher ou masquer dans le devis.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                    )
                  : Text(
                      _isSubTask ? 'Ajouter le sous-poste' : 'Enregistrer l\'ouvrage',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0F3995), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: item == value ? const Color(0xFF0F172A) : const Color(0xFF374151),
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToggleSection({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required void Function(bool) onToggle,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnabled ? color.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isEnabled ? color : const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? color : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              // Toggle label
              Text(
                isEnabled ? 'Visible dans le devis' : 'Masqué',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? color : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: color,
              ),
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }
}
