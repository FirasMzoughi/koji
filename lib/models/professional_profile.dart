class ProfessionalProfile {
  // Identité personnelle
  final String? photoPath;
  final String firstName;
  final String lastName;

  // Informations société
  final String? logoPath;
  final String companyName;
  final String? legalForm; // SARL, EURL, Auto-entrepreneur, etc.
  final String? siret;
  final String? address;
  final String? email;
  final String? phone;
  final String? vatNumber; // TVA intracommunautaire

  // Métiers
  final String? primaryTrade;
  final List<String> specializations;
  final List<String> secondaryTrades;

  ProfessionalProfile({
    this.photoPath,
    this.firstName = '',
    this.lastName = '',
    this.logoPath,
    this.companyName = '',
    this.legalForm,
    this.siret,
    this.address,
    this.email,
    this.phone,
    this.vatNumber,
    this.primaryTrade,
    this.specializations = const [],
    this.secondaryTrades = const [],
  });

  bool get isCompanyInfoComplete {
    return companyName.isNotEmpty &&
        siret != null &&
        siret!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty;
  }

  ProfessionalProfile copyWith({
    String? photoPath,
    String? firstName,
    String? lastName,
    String? logoPath,
    String? companyName,
    String? legalForm,
    String? siret,
    String? address,
    String? email,
    String? phone,
    String? vatNumber,
    String? primaryTrade,
    List<String>? specializations,
    List<String>? secondaryTrades,
  }) {
    return ProfessionalProfile(
      photoPath: photoPath ?? this.photoPath,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      logoPath: logoPath ?? this.logoPath,
      companyName: companyName ?? this.companyName,
      legalForm: legalForm ?? this.legalForm,
      siret: siret ?? this.siret,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vatNumber: vatNumber ?? this.vatNumber,
      primaryTrade: primaryTrade ?? this.primaryTrade,
      specializations: specializations ?? this.specializations,
      secondaryTrades: secondaryTrades ?? this.secondaryTrades,
    );
  }
}
