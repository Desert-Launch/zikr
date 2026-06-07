import 'package:flutter/services.dart';

/// this formatter will format the date input to be in the format of `dd/MM/yyyy`
/// where the '/' are put automatically
class DateFormatter extends TextInputFormatter {
  const DateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll('/', ''); // Remove existing slashes

    /// DAY
    int day = 0;
    if (newText.length == 1) {
      day = int.tryParse(newText) ?? 0;
      if (day >= 4) {
        newText = '0$newText'; // Auto-format 4+ as '04'
      }
    } else if (newText.length == 2) {
      day = int.tryParse(newText.substring(0, 2)) ?? 0;
    }

    if (day > 31) {
      return oldValue; // Reject invalid day
    }

    /// MONTH
    int month = 0;
    if (newText.length == 3) {
      day = int.tryParse(newText.substring(0, 2)) ?? 0;
      month = int.tryParse(newText.substring(2, 3)) ?? 0;
      if (month >= 2) {
        newText = '${day}0$month'; // Auto-format 2+ as '02'
      }
    } else if (newText.length == 4) {
      month = int.tryParse(newText.substring(2, 4)) ?? 0;
    }

    if (month > 12) {
      return oldValue; // Reject invalid month
    }

    /// YEAR
    int year = 0;
    if (newText.length == 5) {
      year = int.tryParse(newText[4]) ?? 0;
      if (year >= 3) {
        return oldValue; // Reject invalid year
      }
    } else if (newText.length == 8) {
      year = int.tryParse(newText.substring(4, 8)) ?? 0;
      if (year > DateTime.now().year || year < 1900) {
        return oldValue; // Reject invalid year
      }
    }

    final buffer = StringBuffer();

    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      // Add slashes after 2nd and 4th digits
      if ((i == 1 || i == 3) && newText.length > i + 1) {
        buffer.write('/');
      }
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
