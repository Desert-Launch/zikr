import 'package:flutter/material.dart';

extension NumExt on num {
  Widget get widthBox => SizedBox(width: toDouble());
}
