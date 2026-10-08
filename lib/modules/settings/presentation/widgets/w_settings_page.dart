import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';

/// The small pages Settings opens (contact, share, rate): the green header
/// over a scrolling column on the settings canvas.
class WSettingsPage extends StatelessWidget {
  const WSettingsPage({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          WGradientAppBar(title: title),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(19.w, 18.h, 19.w, 24.h + MediaQuery.paddingOf(context).bottom),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
