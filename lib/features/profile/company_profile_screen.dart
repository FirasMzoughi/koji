import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _dailyRateController = TextEditingController();
  final _hoursPerDayController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _legalFormController = TextEditingController();
  final _siretController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _tvaController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  String? _currentLogoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _hoursPerDayController.dispose();
    _businessNameController.dispose();
    _legalFormController.dispose();
    _siretController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tvaController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        final userData =
            await ref.read(userRepositoryProvider).getUser(user.id);
        final businessInfo =
            userData?['business_info'] as Map<String, dynamic>?;
        _currentLogoUrl = userData?['logo_url'] as String?;

        if (businessInfo != null) {
          _dailyRateController.text =
              (businessInfo['dailyRate'] as num?)?.toString() ?? '350';
          _hoursPerDayController.text =
              (businessInfo['hoursPerDay'] as num?)?.toString() ?? '7';
          _businessNameController.text = businessInfo['raisonSociale'] ?? '';
          _legalFormController.text = businessInfo['formeJuridique'] ?? '';
          _siretController.text = businessInfo['siret'] ?? '';
          _emailController.text = businessInfo['emailPro'] ?? '';
          _phoneController.text = businessInfo['phone'] ?? '';
          _addressController.text = businessInfo['address'] ?? '';
          _tvaController.text = businessInfo['tva'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de chargement: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload logo if selected
      String? logoUrl = _currentLogoUrl;
      if (_imageFile != null) {
        logoUrl = await ref.read(userRepositoryProvider).uploadBusinessLogo(
              user.id,
              _imageFile!.path,
            );
      }

      final dailyRate = double.tryParse(_dailyRateController.text) ?? 350.0;
      final hoursPerDay = double.tryParse(_hoursPerDayController.text) ?? 7.0;

      await ref.read(userRepositoryProvider).updateBusinessInfo(
            uid: user.id,
            raisonSociale: _businessNameController.text,
            formeJuridique: _legalFormController.text,
            siret: _siretController.text,
            emailPro: _emailController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            tva: _tvaController.text,
            dailyRate: dailyRate,
            hoursPerDay: hoursPerDay,
            logoUrl: logoUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profil Entreprise',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A),
                                  width: 3,
                                ),
                                color: Colors.white,
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_currentLogoUrl != null
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(_currentLogoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (_imageFile == null &&
                                      _currentLogoUrl == null)
                                  ? const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: Color(0xFF1E3A8A),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Changer le logo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pricing Section
                    _buildSectionTitle('Tarification'),
                    _buildPricingCard(),
                    const SizedBox(height: 24),

                    // Business Info Section
                    _buildSectionTitle('Informations Entreprise'),
                    _buildBusinessInfoCard(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Daily Rate
            TextFormField(
              controller: _dailyRateController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Tarif journalier (€ HT / jour)',
                prefixIcon: const Icon(Icons.euro, color: Color(0xFF1E3A8A)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un tarif journalier';
                }
                if (double.tryParse(value) == null) {
                  return 'Valeur invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hours per Day
            TextFormField(
              controller: _hoursPerDayController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Heures par jour',
                prefixIcon:
                    const Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer les heures par jour';
                }
                final hours = double.tryParse(value);
                if (hours == null || hours <= 0) {
                  return 'Valeur invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Calculated hourly rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        'Coût horaire',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _calculateHourlyRate(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateHourlyRate() {
    final dailyRate = double.tryParse(_dailyRateController.text);
    final hoursPerDay = double.tryParse(_hoursPerDayController.text);

    if (dailyRate != null && hoursPerDay != null && hoursPerDay > 0) {
      final hourlyRate = dailyRate / hoursPerDay;
      return '${hourlyRate.toStringAsFixed(2)} € / h';
    }
    return '-- € / h';
  }

  Widget _buildBusinessInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _businessNameController,
              label: 'Raison sociale',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _legalFormController,
              label: 'Forme juridique',
              icon: Icons.gavel,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _siretController,
              label: 'SIRET',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email professionnel',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Adresse',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tvaController,
              label: 'Numéro TVA',
              icon: Icons.receipt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
