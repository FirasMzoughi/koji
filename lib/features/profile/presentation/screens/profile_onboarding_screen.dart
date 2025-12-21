import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/models/trade_data.dart';
import 'package:koji/providers/professional_profile_provider.dart';
import 'package:koji/features/dashboard/presentation/widgets/company_card.dart';
import 'package:koji/providers/account_provider.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _legalFormController = TextEditingController();
  final _siretController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vatController = TextEditingController();

  String? _photoPath;
  String? _logoPath;
  Trade? _selectedTrade;
  Set<String> _selectedSpecializations = {};
  Set<String> _selectedSecondaryTrades = {};

  @override
  void initState() {
    super.initState();
    // Charger le profil existant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(professionalProfileProvider);
      _loadProfile(profile);
    });
  }

  void _loadProfile(profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _companyNameController.text = profile.companyName;
    _legalFormController.text = profile.legalForm ?? '';
    _siretController.text = profile.siret ?? '';
    _addressController.text = profile.address ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _vatController.text = profile.vatNumber ?? '';
    _photoPath = profile.photoPath;
    _logoPath = profile.logoPath;
    
    if (profile.primaryTrade != null) {
      _selectedTrade = Trade.values.firstWhere(
        (t) => t.displayName == profile.primaryTrade,
        orElse: () => Trade.other,
      );
    }
    _selectedSpecializations = Set.from(profile.specializations);
    _selectedSecondaryTrades = Set.from(profile.secondaryTrades);
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _legalFormController.dispose();
    _siretController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      setState(() {
        if (isLogo) {
          _logoPath = image.path;
        } else {
          _photoPath = image.path;
        }
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ref.read(professionalProfileProvider.notifier).updateProfile(
            ref.read(professionalProfileProvider).copyWith(
                  photoPath: _photoPath,
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  logoPath: _logoPath,
                  companyName: _companyNameController.text,
                  legalForm: _legalFormController.text.isEmpty
                      ? null
                      : _legalFormController.text,
                  siret: _siretController.text.isEmpty
                      ? null
                      : _siretController.text,
                  address: _addressController.text.isEmpty
                      ? null
                      : _addressController.text,
                  email: _emailController.text.isEmpty
                      ? null
                      : _emailController.text,
                  phone: _phoneController.text.isEmpty
                      ? null
                      : _phoneController.text,
                  vatNumber: _vatController.text.isEmpty
                      ? null
                      : _vatController.text,
                  primaryTrade: _selectedTrade?.displayName,
                  specializations: _selectedSpecializations.toList(),
                  secondaryTrades: _selectedSecondaryTrades.toList(),
                ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil enregistré avec succès'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(professionalProfileProvider);
    final isCompanyComplete = profile.isCompanyInfoComplete;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Subscription Section for Startups
            if (ref.watch(subscriptionStatusProvider) == SubscriptionStatus.free) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.rocket_launch,
                        size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Passez en mode Startup',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Débloquez toutes les fonctionnalités et propulsez votre activité.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Pricing Cards
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(subscriptionStatusProvider.notifier)
                                  .state = SubscriptionStatus.monthly;
                              // In real app, navigate to payment
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Mensuel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '99€',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '/mois',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(subscriptionStatusProvider.notifier)
                                  .state = SubscriptionStatus.annual;
                              // In real app, navigate to payment
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6F00),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'SAVE 20%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Annuel',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1A237E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '990€',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A237E),
                                    ),
                                  ),
                                  Text(
                                    '/an',
                                    style: TextStyle(
                                      color:
                                          const Color(0xFF1A237E).withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Company Card Preview
            if (_companyNameController.text.isNotEmpty && ref.watch(subscriptionStatusProvider) != SubscriptionStatus.free) ...[
              CompanyCard(
                companyName: _companyNameController.text,
                siret: _siretController.text,
              ),
              const SizedBox(height: 32),
            ],

            // Section 1: Identité personnelle
            _buildSectionCard(
              title: 'Identité personnelle',
              icon: Icons.person,
              children: _buildPersonalInfoSection(),
            ),
            const SizedBox(height: 24),

            // Section 2: Société
            _buildSectionCard(
              title: 'Société',
              icon: Icons.business,
              children: _buildCompanySection(),
            ),
            const SizedBox(height: 24),

            // Section 3: Métiers et spécialisations
            _buildSectionCard(
              title: 'Métiers et spécialisations',
              icon: Icons.construction,
              children: _buildTradeSection(),
            ),
            const SizedBox(height: 24),

            // Warning si société incomplète
            if (!isCompanyComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complétez les informations de votre société pour pouvoir générer des devis.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF1A237E).withOpacity(0.4),
                ),
                child: Text(
                  'Enregistrer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1A237E), size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          children,
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1A237E).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF1A237E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ces informations seront utilisées automatiquement dans l\'en-tête de vos devis et factures.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        // Photo de profil
        Center(
          child: GestureDetector(
            onTap: () => _pickImage(false),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A237E).withOpacity(0.05),
                  backgroundImage:
                      _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? const Icon(Icons.person, size: 50, color: Color(0xFF1A237E))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _firstNameController,
          label: 'Prénom',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Nom',
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildCompanySection() {
    return Column(
      children: [
        _buildInfoBanner(),
        const SizedBox(height: 24),
        // Logo société
        Center(
          child: GestureDetector(
            onTap: () => _pickImage(true),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(_logoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 32, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Logo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _companyNameController,
          label: 'Raison sociale',
          icon: Icons.business_outlined,
          isRequired: true,
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _legalFormController,
          label: 'Forme juridique',
          icon: Icons.account_balance_outlined,
          hint: 'SARL, EURL...',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _siretController,
          label: 'SIRET',
          icon: Icons.badge_outlined,
          isRequired: true,
          isNumber: true,
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Adresse du siège social',
          icon: Icons.location_on_outlined,
          isRequired: true,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email professionnel',
          icon: Icons.email_outlined,
          isRequired: true,
          isEmail: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone_outlined,
          isPhone: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _vatController,
          label: 'TVA intracommunautaire',
          icon: Icons.euro_outlined,
          hint: 'Optionnel',
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool isNumber = false,
    bool isEmail = false,
    bool isPhone = false,
    String? hint,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: isNumber
          ? TextInputType.number
          : isEmail
              ? TextInputType.emailAddress
              : isPhone
                  ? TextInputType.phone
                  : TextInputType.text,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Champ obligatoire';
              }
              if (isEmail && !value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildTradeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métier principal
        Text(
          'Métier principal',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Trade.values.map((trade) {
            final isSelected = _selectedTrade == trade;
            return ChoiceChip(
              label: Text(trade.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTrade = selected ? trade : null;
                  _selectedSpecializations.clear();
                });
              },
              selectedColor: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF263238),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
        
        // Spécialisations
        if (_selectedTrade != null) ...[
          const SizedBox(height: 24),
          Text(
            'Spécialisations',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 12),
          ...TradeSpecializations.getSpecializations(_selectedTrade!).map(
            (spec) => CheckboxListTile(
              title: Text(spec),
              value: _selectedSpecializations.contains(spec),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedSpecializations.add(spec);
                  } else {
                    _selectedSpecializations.remove(spec);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF1A237E),
            ),
          ),
        ],

        // Métiers secondaires
        const SizedBox(height: 24),
        Text(
          'Métiers secondaires (optionnel)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Donnant accès aux postes correspondants dans les dashboards',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Trade.values
              .where((t) => t != _selectedTrade)
              .map((trade) {
            final isSelected = _selectedSecondaryTrades.contains(trade.displayName);
            return FilterChip(
              label: Text(trade.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSecondaryTrades.add(trade.displayName);
                  } else {
                    _selectedSecondaryTrades.remove(trade.displayName);
                  }
                });
              },
              selectedColor: const Color(0xFFFF6F00).withOpacity(0.1),
              checkmarkColor: const Color(0xFFFF6F00),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF6F00) : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6F00) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
