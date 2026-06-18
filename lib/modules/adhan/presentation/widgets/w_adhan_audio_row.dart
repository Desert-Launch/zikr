import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// A selectable adhan voice row. Tapping the row selects the voice; the inline
/// controls preview (play/stop) and manage the downloaded copy:
///
/// * bundled voice → no download control (the audio always ships with the app)
/// * downloadable + not on disk → a download button
/// * downloading → a progress ring
/// * downloaded → a delete button
class WAdhanAudioRow extends StatelessWidget {
  const WAdhanAudioRow({
    super.key,
    required this.adhan,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPlay,
    required this.onStop,
    this.loading = false,
    this.downloadable = false,
    this.downloaded = false,
    this.downloading = false,
    this.progress,
    this.onDownload,
    this.onDelete,
  });

  final MAdhan adhan;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  /// Preview audio for this voice is buffering/loading.
  final bool loading;

  /// Remote voice that can be fetched (non-bundled with a full URL).
  final bool downloadable;

  /// Full file is present on disk.
  final bool downloaded;

  /// A download for this voice is in flight.
  final bool downloading;

  /// 0.0–1.0 while downloading, or null when the total isn't known yet.
  final double? progress;

  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  static const _green = Color(0xFF42BE88);
  static const _teal = Color(0xFF2F7E63);
  static const _ink = Color(0xFF303030);
  static const _danger = Color(0xFFD96A6A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: SizedBox(
        height: 72.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              const WAdhanIconCircle(icon: Icons.notifications_none_rounded),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  adhan.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: selected ? _green : _ink,
                  ),
                ),
              ),
              if (selected) ...[
                Icon(Icons.check_rounded, color: _green, size: 22.r),
                SizedBox(width: 8.w),
              ],
              _manageControl(),
              if (loading)
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _teal,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: playing ? onStop : onPlay,
                  icon: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: _teal,
                    size: 27.r,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The download / delete / progress control. Bundled voices have nothing to
  /// manage, so this collapses to an empty box.
  Widget _manageControl() {
    if (downloading) {
      return SizedBox(
        width: 27.r,
        height: 27.r,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          color: _teal,
        ),
      );
    }
    if (downloaded) {
      return IconButton(
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline_rounded, color: _danger, size: 24.r),
      );
    }
    if (downloadable) {
      return IconButton(
        onPressed: onDownload,
        icon: Icon(Icons.download_rounded, color: _teal, size: 24.r),
      );
    }
    return const SizedBox.shrink();
  }
}
