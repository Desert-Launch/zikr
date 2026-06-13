import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Row above the category list: a "back to categories" button and the category
/// title.
class WAzkarListTitle extends StatelessWidget {
  const WAzkarListTitle({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: Text('azkar_back_categories'.tr()),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
