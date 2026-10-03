import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:collection/collection.dart';

extension StringExtensions on String {
  String get translated => tr().replaceAll(' - 404', '');

  T? toEnum<T>(List<T> enumValues) {
    return enumValues.firstWhereOrNull((e) => e.toString().split('.').lastOrNull == this);
  }
}

extension StringNullExtensions on String? {
}
