class AuthValidators {
  AuthValidators._();

  static String? validateIndianMobile(String value) {
    final digits = value.trim();
    if (digits.isEmpty) {
      return 'Mobile number is required';
    }
    if (digits.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  static String? validateOtp(String value) {
    final otp = value.trim();
    if (otp.isEmpty) {
      return 'OTP is required';
    }
    if (otp.length != 4) {
      return 'Enter the 4-digit OTP';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(otp)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  static String? validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateExamSelection(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your target exam';
    }
    return null;
  }
}
