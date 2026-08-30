import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/core/utils/helper/share_image_helper.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/widgets/share_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_extras_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_format_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_image_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_preview.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_range_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_section.dart';
import 'package:share_plus/share_plus.dart';

/// The sheet that stands between tapping share and the system share sheet:
/// what shape the verses take, how many of them go, what commentary goes with
/// them, and whether the app signs the result.
///
/// It opens on the tapped verse alone with nothing attached, which is what a
/// reader who just wants to send an ayah gets by pressing share twice.
class WAyahShareSheet extends StatefulWidget {
  const WAyahShareSheet({super.key});

  static Future<void> show(BuildContext context, ParamAyahRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.brand.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => BlocProvider<CBAyahShare>(
        create: (_) => Modular.get<CBAyahShare>()..open(ref),
        child: const WAyahShareSheet(),
      ),
    );
  }

  @override
  State<WAyahShareSheet> createState() => _WAyahShareSheetState();
}

class _WAyahShareSheetState extends State<WAyahShareSheet> {
  /// The boundary the rendered card is captured from — see [WSharePreview].
  final GlobalKey _card = GlobalKey();

  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decoded ahead of the first capture: an asset still loading paints as
    // nothing, and the card is captured a frame after the reader taps share.
    precacheImage(const AssetImage(WShareImageCard.logoAsset), context);
  }

  /// The rect an iPad points its share popover at. Without it the popover
  /// opens in the corner of the screen, unanchored to anything.
  Rect _origin() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }

  Future<void> _share(SAyahShare state) async {
    final content = state.content;
    if (content == null || _sharing) return;
    setState(() => _sharing = true);
    final origin = _origin();
    var shared = true;
    try {
      if (state.isImage) {
        shared = await ShareImageHelper.shareBoundary(
          boundaryKey: _card,
          fileName:
              'ayah-${content.surah.number}-${content.from}-${content.to}',
          // The card carries the app's mark but not its address — a URL in a
          // picture cannot be tapped, so it travels as the share's caption.
          text: state.appBadge
              ? '${shareViaLabel()}\n${AppConfig.shareAppUrl}'
              : null,
          origin: origin,
        );
      } else {
        await Share.share(buildShareTextFor(state), sharePositionOrigin: origin);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
    if (!mounted) return;
    if (!shared) {
      AppAlert.error('quran_share_failed'.tr());
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: BlocBuilder<CBAyahShare, SAyahShare>(
        builder: (context, state) {
          final surahName = shareSurahName(state.content?.surah, state.surah);
          return Column(
            children: [
              _Header(label: shareAyahLabel(surahName, state.from)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                  children: [
                    WSharePreview(boundaryKey: _card, height: 230.h),
                    SizedBox(height: 18.h),
                    const WShareFormatPicker(),
                    SizedBox(height: 18.h),
                    WShareRangePicker(surahName: surahName),
                    SizedBox(height: 18.h),
                    const WShareExtrasPicker(),
                    SizedBox(height: 18.h),
                    const _BadgeSwitch(),
                  ],
                ),
              ),
              _Footer(
                label: shareCountLabel(state.count),
                busy: _sharing,
                enabled: state.content != null,
                onTap: () => _share(state),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: context.brand.primary,
            ),
          ),
          Expanded(
            child: Text(
              'quran_share_title'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: context.brand.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 22.r, color: context.brand.muted),
          ),
        ],
      ),
    );
  }
}

/// "Add the app badge" — whether the share signs itself.
class _BadgeSwitch extends StatelessWidget {
  const _BadgeSwitch();

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBAyahShare>(context);
    return BlocSelector<CBAyahShare, SAyahShare, bool>(
      selector: (s) => s.appBadge,
      builder: (context, on) => WShareSection(
        label: 'quran_share_badge_section'.tr(),
        children: [
          WShareRow(
            title: 'quran_share_badge'.tr(),
            onTap: cubit.toggleAppBadge,
            trailing: Switch.adaptive(
              value: on,
              onChanged: (_) => cubit.toggleAppBadge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
        child: WAppButton(
          title: label,
          isLoading: busy,
          isDisabled: !enabled,
          onTap: onTap,
        ),
      ),
    );
  }
}
