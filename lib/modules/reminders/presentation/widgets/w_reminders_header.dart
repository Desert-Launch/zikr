import 'package:flutter/material.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';

/// Green-gradient rounded header shared by the reminders list and form screens.
/// Thin wrapper over [WGradientAppBar]; the list passes [onAdd] to render the
/// trailing "+" shortcut.
class WRemindersHeader extends StatelessWidget {
  const WRemindersHeader({
    required this.title,
    this.onAdd,
    super.key,
  });

  final String title;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return WGradientAppBar(
      title: title,
      actions: onAdd == null
          ? null
          : [
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
    );
  }
}
