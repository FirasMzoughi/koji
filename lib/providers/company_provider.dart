import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyProfile {
  final List<String> domains;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? siret;
  final String? logoPath;

  CompanyProfile({
    this.domains = const [],
    this.name = '',
    this.email,
    this.phone,
    this.address,
    this.siret,
    this.logoPath,
  });

  CompanyProfile copyWith({
    List<String>? domains,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? siret,
    String? logoPath,
  }) {
    return CompanyProfile(
      domains: domains ?? this.domains,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      siret: siret ?? this.siret,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

class CompanyProfileNotifier extends StateNotifier<CompanyProfile> {
  CompanyProfileNotifier() : super(CompanyProfile());

  void setDomains(List<String> domains) {
    state = state.copyWith(domains: domains);
  }

  void updateInfo({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? siret,
    String? logoPath,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      siret: siret,
      logoPath: logoPath,
    );
  }
}

final companyProfileProvider = StateNotifierProvider<CompanyProfileNotifier, CompanyProfile>((ref) {
  return CompanyProfileNotifier();
});
