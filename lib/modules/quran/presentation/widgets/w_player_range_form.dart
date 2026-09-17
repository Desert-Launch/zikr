import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_choice_row.dart';

/// Surah + from/to pickers and a play button that hands the block to
/// `CBAudioPlayer.playRange`. Starts from the active range when there is one,
/// otherwise from the playing ayah to the end of its surah.
///
/// Per-ayah repeat is not set here: the repeat card's stepper owns it and
/// `playRange` keeps whatever it holds.
class WPlayerRangeForm extends StatefulWidget {
  const WPlayerRangeForm({super.key});

  @override
  State<WPlayerRangeForm> createState() => _WPlayerRangeFormState();
}

class _WPlayerRangeFormState extends State<WPlayerRangeForm> {
  int? _surah;
  int? _fromAyah;
  int? _toAyah;
  List<MSurah> _all = const [];

  @override
  void initState() {
    super.initState();
    final player = Modular.get<CBAudioPlayer>().state;
    final current = player.currentAyah;
    final from = player.options.rangeFrom;
    final to = player.options.rangeTo;
    // An active range wins as long as it is the surah on screen, so the form
    // never proposes a block from a surah the user has since left.
    if (from != null &&
        to != null &&
        (current == null || from.surah == current.surah)) {
      _surah = from.surah;
      _fromAyah = from.ayah;
      _toAyah = to.ayah;
    } else if (current != null) {
      _surah = current.surah;
      _fromAyah = current.ayah;
    }
    _load();
  }

  Future<void> _load() async {
    final res = await Modular.get<RQuran>().getSurahs();
    if (!mounted) return;
    res.fold((_) {}, (list) {
      setState(() {
        _all = list;
        final count = _selected?.totalAyah ?? 0;
        if (count > 0) {
          // A missing "to" means "to the end of the surah".
          _toAyah = (_toAyah ?? count).clamp(1, count);
          _fromAyah = (_fromAyah ?? 1).clamp(1, count);
        }
      });
    });
  }

  MSurah? get _selected {
    for (final s in _all) {
      if (s.number == _surah) return s;
    }
    return null;
  }

  int get _ayahCount => _selected?.totalAyah ?? 0;

  bool get _canPlay {
    final from = _fromAyah;
    final to = _toAyah;
    return _surah != null && from != null && to != null && from <= to;
  }

  void _onSurah(int? v) {
    if (v == null) return;
    setState(() {
      _surah = v;
      _fromAyah = 1;
      _toAyah = _ayahCount;
    });
  }

  void _play() {
    final s = _surah;
    final from = _fromAyah;
    final to = _toAyah;
    if (s == null || from == null || to == null) return;
    Modular.get<CBAudioPlayer>().playRange(
      ParamAyahRef(surah: s, ayah: from),
      ParamAyahRef(surah: s, ayah: to),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final count = _ayahCount;
    final ayat = List<int>.generate(count, (i) => i + 1);
    return Column(
      children: [
        _DropField<int>(
          label: 'player_range_surah'.tr(),
          hint: 'player_range_surah_hint'.tr(),
          value: _selected?.number,
          items: [
            for (final s in _all)
              DropdownMenuItem(
                value: s.number,
                child: Text(
                  '${s.number}. ${s.arabic.isNotEmpty ? s.arabic : s.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _all.isEmpty ? null : _onSurah,
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _DropField<int>(
                label: 'player_range_from'.tr(),
                value: _inRange(_fromAyah, count),
                items: [
                  for (final n in ayat)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: count == 0
                    ? null
                    : (v) => setState(() => _fromAyah = v),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _DropField<int>(
                label: 'player_range_to'.tr(),
                value: _inRange(_toAyah, count),
                items: [
                  for (final n in ayat)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: count == 0
                    ? null
                    : (v) => setState(() => _toAyah = v),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        WAppButton(
          title: 'player_range_play'.tr(),
          onTap: _play,
          isDisabled: !_canPlay,
          height: 42.h,
          fontSize: 13.sp,
          withShadow: false,
          icon: Icon(Icons.play_arrow_rounded, size: 20.r, color: Colors.white),
        ),
      ],
    );
  }

  /// A dropdown asserts its value is one of its items, so anything outside
  /// the loaded surah's ayah span is shown as unset.
  static int? _inRange(int? v, int count) =>
      v != null && v >= 1 && v <= count ? v : null;
}

/// Caption + dropdown in the shared player track. Uses a plain
/// [DropdownButton] (not the form field) so a programmatic reset — e.g.
/// from/to after a surah change — is reflected immediately.
class _DropField<T> extends StatelessWidget {
  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final hintText = hint;
    return Container(
      height: 42.h,
      padding: EdgeInsetsDirectional.only(start: 10.w, end: 4.w),
      decoration: playerTrackDecoration(context),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: brand.muted,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(12.r),
                icon: Icon(
                  Icons.expand_more_rounded,
                  size: 20.r,
                  color: brand.muted,
                ),
                hint: hintText == null
                    ? null
                    : Text(
                        hintText,
                        style: TextStyle(fontSize: 12.sp, color: brand.muted),
                      ),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: brand.onSurface,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
