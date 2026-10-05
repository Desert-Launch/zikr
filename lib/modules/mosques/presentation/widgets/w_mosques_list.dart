import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosque_card.dart';

/// The nearby-mosques cards as a sliver, nearest first, with [selectedId]'s
/// card outlined.
///
/// Built all at once rather than lazily: a tapped pin has to be able to scroll
/// to any card, and an unbuilt card has no context to scroll to. The list is
/// capped at 20, so this stays cheap.
class WMosquesList extends StatelessWidget {
  const WMosquesList({
    required this.mosques,
    required this.selectedId,
    required this.cardKey,
    required this.onSelect,
    required this.onDirections,
    super.key,
  });

  final List<EMosque> mosques;
  final String? selectedId;

  /// The key for a mosque's card, kept by the screen to scroll to it.
  final GlobalKey Function(String mosqueId) cardKey;
  final ValueChanged<String> onSelect;
  final ValueChanged<EMosque> onDirections;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + bottomInset),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            for (final (index, mosque) in mosques.indexed) ...[
              if (index > 0) SizedBox(height: 12.h),
              WMosqueCard(
                key: cardKey(mosque.id),
                rank: index + 1,
                mosque: mosque,
                selected: mosque.id == selectedId,
                onTap: () => onSelect(mosque.id),
                onDirections: () => onDirections(mosque),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
