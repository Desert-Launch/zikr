import 'package:flutter/material.dart';

class CustomPinCodeOptions {
  final void Function(String)? onCompleted;
  final int? length;
  final Color? fillColor;
  final Color? textColor;
  final Color? borderColor;

  const CustomPinCodeOptions({
    this.onCompleted,
    this.length,
    this.fillColor,
    this.textColor,
    this.borderColor,
  });
}
