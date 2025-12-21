import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/models/professional_profile.dart';

class ProfessionalProfileNotifier extends StateNotifier<ProfessionalProfile> {
  ProfessionalProfileNotifier() : super(ProfessionalProfile());

  void updatePersonalInfo({
    String? photoPath,
    String? firstName,
    String? lastName,
  }) {
    state = state.copyWith(
      photoPath: photoPath,
      firstName: firstName,
      lastName: lastName,
    );
  }

  void updateCompanyInfo({
    String? logoPath,
    String? companyName,
    String? legalForm,
    String? siret,
    String? address,
    String? email,
    String? phone,
    String? vatNumber,
  }) {
    state = state.copyWith(
      logoPath: logoPath,
      companyName: companyName,
      legalForm: legalForm,
      siret: siret,
      address: address,
      email: email,
      phone: phone,
      vatNumber: vatNumber,
    );
  }

  void updateTradeInfo({
    String? primaryTrade,
    List<String>? specializations,
    List<String>? secondaryTrades,
  }) {
    state = state.copyWith(
      primaryTrade: primaryTrade,
      specializations: specializations,
      secondaryTrades: secondaryTrades,
    );
  }

  void updateProfile(ProfessionalProfile profile) {
    state = profile;
  }
}

final professionalProfileProvider =
    StateNotifierProvider<ProfessionalProfileNotifier, ProfessionalProfile>(
        (ref) {
  return ProfessionalProfileNotifier();
});
