import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';

/// Dependency-free OTP / PIN field rendered as a row of single-digit boxes.
/// The combined value is written into [controller]; [CustomPinCodeOptions.onCompleted]
/// fires when every box is filled.
class WPinCodeField extends BaseFormField {
  WPinCodeField({super.isRequired = true, super.label = '', super.hint = ''});

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    final options = param?.pinCodeOptions;
    return _PinBoxes(
      controller: controller,
      length: options?.length ?? 6,
      fillColor: options?.fillColor,
      textColor: options?.textColor,
      borderColor: options?.borderColor,
      onCompleted: options?.onCompleted,
      onChanged: param?.onChanged,
    );
  }
}

class _PinBoxes extends StatefulWidget {
  const _PinBoxes({
    required this.controller,
    required this.length,
    this.fillColor,
    this.textColor,
    this.borderColor,
    this.onCompleted,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final Color? fillColor;
  final Color? textColor;
  final Color? borderColor;
  final void Function(String)? onCompleted;
  final void Function(String)? onChanged;

  @override
  State<_PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<_PinBoxes> {
  late final List<TextEditingController> _boxes;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _boxes = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted / autofilled — spread across boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _boxes[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }

    final combined = _boxes.map((c) => c.text).join();
    widget.controller.text = combined;
    widget.onChanged?.call(combined);
    if (combined.length == widget.length) {
      _nodes[index].unfocus();
      widget.onCompleted?.call(combined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final fill = widget.fillColor ?? brand.surface;
    final border = widget.borderColor ?? brand.border;
    final textColor = widget.textColor ?? brand.onSurface;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          return SizedBox(
            width: 48.w,
            height: 56.h,
            child: TextField(
              controller: _boxes[i],
              focusNode: _nodes[i],
              autofocus: i == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onChanged(i, v),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: fill,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: AppColorsLight.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
