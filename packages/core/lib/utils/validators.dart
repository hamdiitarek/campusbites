class Validators {
  static String? validateEmail(String? value, [String? domain]) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Check for valid email format
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    // Check domain if specified
    if (domain != null && domain.isNotEmpty) {
      if (!value.endsWith('@$domain')) {
        return 'Email must end with @$domain';
      }
    }

    return null;
  }

  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegExp = RegExp(r'^01[0125][0-9]{8}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
