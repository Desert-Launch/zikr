import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_compact_header.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_counter_card.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_virtue_card.dart';

class SNAzkarPlayer extends StatefulWidget {
  const SNAzkarPlayer({
    super.key,
    required this.categoryId,
    this.itemIndex = 0,
  });

  final String categoryId;
  final int itemIndex;

  @override
  State<SNAzkarPlayer> createState() => _SNAzkarPlayerState();
}

class _SNAzkarPlayerState extends State<SNAzkarPlayer> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBAzkarSession _cubit = Modular.get<CBAzkarSession>();
  late final BoxAzkarFavorite _favorites = Modular.get<BoxAzkarFavorite>();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    await _cubit.open(widget.categoryId);
    _cubit.jumpTo(widget.itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: _canvas,
        body: BlocBuilder<CBAzkarSession, SAzkarSession>(
          builder: (_, state) {
            final category = state.category;
            final item = state.currentItem;
            if (category == null || item == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final completed = state.countFor(item.id);
            final virtue = item.virtueAr;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: WAzkarCompactHeader(
                    itemCount: category.items.length,
                    completed: category.items
                        .where((item) => state.isComplete(item))
                        .length,
                    favorites: _favorites.all().length,
                    green: _green,
                    onBack: Modular.to.pop,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 28.h),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: Modular.to.pop,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: Text('azkar_back_list'.tr()),
                          ),
                          const Spacer(),
                          Text(
                            category.nameAr,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      WAzkarCounterCard(
                        item: item,
                        completed: completed,
                        green: _green,
                        onTap: _cubit.tap,
                        onReset: _cubit.resetCurrent,
                      ),
                      if (virtue != null && virtue.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        WAzkarVirtueCard(text: virtue, gold: _gold),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
