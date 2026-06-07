import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/extension/text_theme_extension.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

class WDropdownField<T> extends BaseFormField {
  List<T> items;
  T? selectedValue;
  void Function(T?)? onChanged;

  WDropdownField({
    this.items = const [],
    this.onChanged,
    super.isRequired = true,
    super.hint = '',
    super.label = '',
    super.fieldName = '',
  });

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    return WDropdown<T>(
      items: items,
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      label: label,
      onChanged: param?.onChanged,
    );
  }
}

class WDropdown<T> extends StatefulWidget {
  const WDropdown({
    required this.items,
    required this.controller,
    this.hint,
    this.label,
    this.fieldKey,
    this.focusNode,
    this.validate,
    this.onChanged,
    super.key,
  });

  /// Controllers
  final TextEditingController controller;
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  final String? hint;
  final String? label;

  /// Actions
  final String? Function(String?)? validate;
  final List<T> items;
  final void Function(String)? onChanged;

  @override
  State<WDropdown<T>> createState() => _WDropdownState<T>();
}

class _WDropdownState<T> extends State<WDropdown<T>> {
  OverlayEntry? _overlayEntry;

  late String currentCountryPrefix;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleMenu,
      child: WSharedField(
        validatorKey: widget.fieldKey,
        controller: widget.controller,
        focusNode: widget.focusNode,
        hint: widget.hint,
        enabled: false,
        label: widget.label,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: context.brand.primary,
        ),
        onValidate: widget.validate,
        keyboardType: TextInputType.text,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        textStyle: context.textTheme.black14w500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: context.brand.primary),
        ),
      ),
    );
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _removeMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeMenu,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: offset.dx,
              top: (offset.dy + renderBox.size.height) > context.height - 250.h
                  ? offset.dy - 250.h
                  : offset.dy + renderBox.size.height,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: renderBox.size.width,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    width: renderBox.size.width,
                    height: 250.h,
                    constraints: BoxConstraints(
                      maxHeight: 250.h,
                      minHeight: 20.h,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: widget.items.map(_buildMenuItem).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildMenuItem(T item) {
    return InkWell(
      onTap: () {
        widget.controller.text = item.toString();
        widget.onChanged?.call(item.toString());
        _removeMenu();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Text(
              item.toString(),
              style: Theme.of(context).textTheme.black14w500,
            ),
          ],
        ),
      ),
    );
  }
}
