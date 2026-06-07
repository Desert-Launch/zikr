import 'package:quran/core/extension/string_extensions.dart';

/// [InputFieldValidator] is a class that contains all the validations that are used in the app.
class InputFieldValidator {
  /// [isMobileValid] is a function that checks if the mobile number is valid or not.
  static String? isValidMobileNumber(String? value) {
    String phoneNumber = value?.replaceAll('-', '') ?? '';
    RegExp onlyNumbers = RegExp(r'^\d+$');
    if (phoneNumber.isEmpty || phoneNumber.trim().isEmpty) {
      return 'Phone number cant be empty'.translated;
    } else if (!onlyNumbers.hasMatch(phoneNumber)) {
      return 'Phone number must be only numbers.'.translated;
    } else if (phoneNumber.length < 10) {
      return 'Phone number must be 10 digits'.translated;
    }
    return null;
  }

  static String? isInputEmpty({
    required String fieldName,
    required String value,
    int minLength = 2,
    bool isOnlyNumbers = false,
    bool isPassword = false,
  }) {
    RegExp onlyNumbers = RegExp(r'^\d+$');
    if (value.isEmpty || value.trim().isEmpty) {
      return '$fieldName ${'cant be empty'.translated}';
    } else if (isOnlyNumbers && !onlyNumbers.hasMatch(value)) {
      return '$fieldName ${'must be only numbers'.translated}';
    } else if (value.trim().length < minLength && !isPassword) {
      return '$fieldName ${'must be at least'.translated} $minLength ${'characters long'.translated}';
    }

    return null;
  }

  /// [isEmailValid] is a function that checks if the email is valid or not.
  static String? isEmailValid({required String email, bool isRequired = false}) {
    const String pattern = r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$';
    final RegExp regExp = RegExp(pattern);
    if (email.isEmpty && isRequired) {
      return 'Email cant be empty'.translated;
    } else if (!regExp.hasMatch(email) && email.isNotEmpty) {
      return 'Invalid email format'.translated;
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Password cant be empty'.translated;
    } else if ((value?.length ?? 0) < 8) {
      return 'Password must be at least 8 characters long'.translated;
    }
    return null;
  }

  static String? isValidConfirmPassword(String? value, String? confirmValue) {
    if (value?.isEmpty ?? true) {
      return 'Confirm password cant be empty'.translated;
    } else if (value != confirmValue) {
      return 'Confirm Password doesnt match'.translated;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value?.isEmpty ?? true) {
      return 'Confirm password cant be empty'.translated;
    } else if (value != password) {
      return 'Confirm Password doesnt match'.translated;
    }
    return null;
  }

  static String? isValedNumber(String? value) {
    RegExp onlyNumbers = RegExp(r'^\d+$');
    if (value?.isNotEmpty == true) {
      if (!onlyNumbers.hasMatch(value ?? '')) {
        return 'Phone number must be only numbers.'.translated;
      }
    }
    return null;
  }

  static String? validateRequired({required String? value, required String fieldName, String? customMessage}) {
    if (value == null || value.isEmpty) {
      return customMessage ??
          (fieldName.isNotEmpty ? '$fieldName ${'is required'.translated}' : "This field is required".translated);
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value ?? '')) {
      return 'Enter a valid email address'.translated;
    }

    return null;
  }

  static String? validatePhoneNumber(String phone) {
    if (phone.length != 10) {
      return 'Phone number should be 10 digits'.translated;
    }

    if (phone.startsWith('0')) {
      return 'Phone number should not start with 0'.translated;
    }
    if (!phone.isValidNumber()) {
      return 'Invalid phone number'.translated;
    }
    return null;
  }

  static String? validateOptionalPhoneNumber(String? phone) {
    final String phoneNumber = (phone ?? '').replaceAll(' ', '');
    if (phoneNumber.isEmpty) return null;
    // if (!RegExp(r'^[3-7]\d{7}$').hasMatch(phoneNumber)) {
    //   return 'Enter a valid Qatar phone number'.translated;
    // }
    return null;
  }

  static String? validateQatarPhoneRequired(String? phone) {
    final String? requiredError = validateRequired(value: phone, fieldName: 'Phone number'.translated);
    if (requiredError != null) {
      return requiredError;
    }
    return validateOptionalPhoneNumber(phone);
  }

  static String? isValidEgyptianNumber(String phoneNumber) {
    final RegExp regex = RegExp(r'^\+20(1[0-9]{9})$');
    return regex.hasMatch(phoneNumber) ? null : 'Invalid'.translated;
  }

  static String? isValidUaeNumber(String phoneNumber) {
    final RegExp regex = RegExp(r'^\+971(5[0-9]{8}|[2-9][0-9]{7})$');
    return regex.hasMatch(phoneNumber) ? null : 'Invalid'.translated;
  }

  static String? isValidGermanNumber(String phoneNumber) {
    final RegExp regex = RegExp(r'^\+49([1-9][0-9]{6,13})$');
    return regex.hasMatch(phoneNumber) ? null : 'Invalid'.translated;
  }

  static String? validateOptionalEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address'.translated;
    }
    return null;
  }

  static String? validateOptionalLink(String value) {
    if (value.isEmpty) return null;
    final RegExp urlRegex = RegExp(
      r'^(https?:\/\/)?([\w\d-]+\.){1,2}[a-z]{2,6}(:[0-9]{1,5})?(\/.*)?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL'.translated;
    }
    return null; // Return null if the website is valid
  }

  static String? validateRequiredString(String value) {
    if (value.isEmpty) return 'Required'.translated;
    return null;
  }

  /// Validates that value contains first and last name separated by space.
  static String? validateFullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return 'Name is required'.translated;
    }
    final RegExp lettersOnly = RegExp(r'^[\p{L}\s]+$', unicode: true);
    if (!lettersOnly.hasMatch(v)) {
      return 'Name must contain letters only'.translated;
    }
    // final parts = v.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    // if (parts.length < 2) {
    //   return 'Enter first and last name'.translated;
    // }
    // Optionally ensure minimal length for each part
    if (v.length < 4) {
      return 'Name must be more than 3 letter'.translated;
    }
    return null;
  }

  static String? validateDateRequired(String? value) {
    if (value != null && value.isEmpty) return 'Please enter date of birth'.translated;
    return null;
  }

  static String? validateDate(String? value) {
    if (value != null && value.length < 10) return 'Date is invalid'.translated;
    return null;
  }
}
