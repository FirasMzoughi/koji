import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track whether the user selected Pro (Entreprise) or Regular (Particulier) account
/// true = Pro (Entreprise), false = Regular (Particulier), null = not selected yet
final accountTypeProvider = StateProvider<bool?>((ref) => null);
