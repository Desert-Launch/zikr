import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newRawText = newValue.text.replaceAll(' ', '');
    // Local number formatted as XXXX XXXX, e.g. 3334 2222.

    List<String> newStringList = newRawText.split('');

    if (newStringList.length > 4) {
      newStringList.insert(4, ' ');
    }

    int cursorPosition = newValue.selection.baseOffset;
    int formattedCursorPosition = cursorPosition;
    int spaceCount = newStringList.where((char) => char == ' ').length;
    formattedCursorPosition += spaceCount;

    return TextEditingValue(
      text: newStringList.join(),
      selection: TextSelection.collapsed(offset: formattedCursorPosition.clamp(0, newStringList.length)),
    );
  }
}
