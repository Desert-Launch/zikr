import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_v4_page.dart'
    show kMushafSideMargin, readerBackground;

/// The seam between two pages, drawn only in continuous mode.
///
/// Paged mode has no use for one: there, the page break *is* the gesture. But
/// scrolling straight through, the foot of one page and the running head of the
/// next arrive back to back with nothing between them, and the boundary a
/// reader actually counts in — "I am on page 3" — dissolves into the stream. A
/// hairline is enough to put it back without pretending to be a page edge.
///
/// It paints the reading surface behind itself, so the gap it opens is the same
/// paper as the pages either side rather than a stripe of the scaffold showing
/// through.
class WMushafPageDivider extends StatelessWidget {
  const WMushafPageDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBMushafReader, SMushafReader, ReaderTheme>(
      selector: (s) => s.theme,
      builder: (context, theme) => ColoredBox(
        color: readerBackground(theme),
        child: Padding(
          padding: EdgeInsets.symmetric(
            // Held to the page's own margin so the rule lines up with the text
            // block above and below it rather than cutting the full width.
            horizontal: kMushafSideMargin,
            vertical: 9.h,
          ),
          child: Container(height: 1, color: _seamColor(theme)),
        ),
      ),
    );
  }

  /// Faint on purpose — a page seam is a piece of information, not a piece of
  /// furniture, and a rule with any weight to it reads as a divider between two
  /// documents rather than two leaves of one.
  Color _seamColor(ReaderTheme theme) => switch (theme) {
    ReaderTheme.dark => Colors.white.withValues(alpha: 0.14),
    ReaderTheme.light || ReaderTheme.white => Colors.black.withValues(
      alpha: 0.10,
    ),
  };
}
