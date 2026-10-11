import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Loads a bundled markdown [asset] and renders it as a scrollable view.
/// [dense] shrinks the type scale for embedding the text inside a card.
class WMarkdownView extends StatefulWidget {
  const WMarkdownView({
    super.key,
    required this.asset,
    required this.padding,
    this.dense = false,
  });

  final String asset;
  final EdgeInsets padding;
  final bool dense;

  @override
  State<WMarkdownView> createState() => _WMarkdownViewState();
}

class _WMarkdownViewState extends State<WMarkdownView> {
  // Kept across rebuilds so a parent rebuild doesn't restart the load and
  // flash the spinner; replaced only when the asset (language) changes.
  late Future<String> _content = rootBundle.loadString(widget.asset);

  @override
  void didUpdateWidget(WMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _content = rootBundle.loadString(widget.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dense = widget.dense;
    return FutureBuilder<String>(
      future: _content,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Markdown(
          data: data,
          padding: widget.padding,
          styleSheet: MarkdownStyleSheet(
            h1: TextStyle(
              fontSize: (dense ? 18 : 22).sp,
              fontWeight: FontWeight.w800,
              color: AppColorsLight.primaryDark,
            ),
            h2: TextStyle(
              fontSize: (dense ? 15 : 17).sp,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.primary,
            ),
            p: TextStyle(fontSize: (dense ? 13 : 14).sp, height: 1.7),
            listBullet: TextStyle(fontSize: (dense ? 13 : 14).sp),
          ),
        );
      },
    );
  }
}
