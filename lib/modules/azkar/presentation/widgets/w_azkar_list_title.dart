import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';

/// Row above the category list: a "back to categories" button. The category
/// name itself lives in the header.
class WAzkarListTitle extends StatelessWidget {
  const WAzkarListTitle({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const WLocalizeRotation(
            reverse: true,
            child: Icon(Icons.arrow_back_rounded, size: 16),
          ),
          label: Text('azkar_back_categories'.tr()),
        ),
        const Spacer(),
      ],
    );
  }
}
