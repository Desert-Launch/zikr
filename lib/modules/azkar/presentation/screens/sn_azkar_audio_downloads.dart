import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio_downloads.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio_downloads.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_reader_card.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_storage_card.dart';

/// إدارة الأصوات — the adhkar audio download manager.
///
/// The whole feature reduces to one idea here: pick a sheikh, download the
/// voice, and the adhkar then play without a connection.
class SNAzkarAudioDownloads extends StatefulWidget {
  const SNAzkarAudioDownloads({super.key});

  @override
  State<SNAzkarAudioDownloads> createState() => _SNAzkarAudioDownloadsState();
}

class _SNAzkarAudioDownloadsState extends State<SNAzkarAudioDownloads> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBAzkarAudioDownloads _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBAzkarAudioDownloads>()..load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(
              title: 'azkar_audio_downloads_title'.tr(),
              subtitle: 'azkar_audio_downloads_subtitle'.tr(),
            ),
            Expanded(
              child: BlocBuilder<CBAzkarAudioDownloads, SAzkarAudioDownloads>(
                builder: (context, state) {
                  if (state.status == AzkarDownloadsStatus.loading &&
                      state.readers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.readers.isEmpty) {
                    return Center(
                      child: WEmptyState(
                        icon: Icons.headphones_outlined,
                        title: 'azkar_audio_no_readers'.tr(),
                        subtitle: state.error,
                        isDark: false,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(top: 10.h, bottom: 24.h),
                    itemCount: state.readers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return WAzkarStorageCard(
                          usage: state.storage,
                          readers: state.readers,
                          onDeleteAll: () => _confirmDeleteAll(context),
                        );
                      }
                      final reader = state.readers[index - 1];
                      final stats = state.statsFor(reader.id);
                      return WAzkarReaderCard(
                        reader: reader,
                        stats: stats,
                        progress: state.progress[reader.id],
                        isPreferred: state.preferredReaderId == reader.id,
                        onTap: () async {
                          await Modular.to.pushNamed(
                            AzkarRoutes.fullAudioReader(reader.id),
                          );
                          await _cubit.refresh();
                        },
                        onDownload: () => _cubit.start(reader.id),
                        onCancel: () => _cubit.cancel(reader.id),
                        onDelete: () => _confirmDeleteReader(
                          context,
                          reader.id,
                          reader.displayName(
                            LocalizeAndTranslate.getLanguageCode() == 'ar',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deleting a whole reader's files is not undoable and can be many hundreds
  /// of megabytes of re-download, so it always asks first.
  Future<void> _confirmDeleteReader(
    BuildContext context,
    String readerId,
    String name,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'azkar_audio_delete_reader_title'.tr(),
      message: '${'azkar_audio_delete_reader_message'.tr()} $name',
    );
    if (confirmed) await _cubit.deleteReader(readerId);
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'azkar_audio_delete_all_title'.tr(),
      message: 'azkar_audio_delete_all_message'.tr(),
    );
    if (confirmed) await _cubit.deleteAll();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final brand = context.brand;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: 16.sp)),
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'azkar_audio_delete'.tr(),
              style: TextStyle(color: brand.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
