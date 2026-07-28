class Validators {
  Validators._();

  static bool isValidIndianMobile(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) return false;
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly);
  }

  static String? mobileError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Mobile number is required';
    if (trimmed.length < 10) return 'Enter a valid 10-digit mobile number';
    if (!isValidIndianMobile(trimmed)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  static bool isValidOtp(String value) {
    return RegExp(r'^\d{6}$').hasMatch(value.trim());
  }

  static String? otpError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'OTP is required';
    if (trimmed.length < 6) return 'Enter the 6-digit OTP';
    if (!isValidOtp(trimmed)) return 'OTP must contain only digits';
    return null;
  }

  static String? nameError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(trimmed)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }
}
