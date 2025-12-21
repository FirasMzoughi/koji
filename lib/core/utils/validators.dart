class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  // Phone validation (French format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final phoneRegex = RegExp(r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$');
    
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }

  // SIRET validation
  static String? validateSiret(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le SIRET est requis';
    }
    
    final cleanValue = value.replaceAll(' ', '');
    
    if (cleanValue.length != 14) {
      return 'Le SIRET doit contenir 14 chiffres';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Le SIRET ne doit contenir que des chiffres';
    }
    
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Cette valeur'} doit être un nombre';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, {String? fieldName}) {
    final numberError = validateNumber(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (value != null && value.isNotEmpty) {
      final number = double.parse(value);
      if (number <= 0) {
        return '${fieldName ?? 'Cette valeur'} doit être positive';
      }
    }
    
    return null;
  }
}
