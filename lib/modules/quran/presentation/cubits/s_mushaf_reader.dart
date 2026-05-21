import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

enum ReaderTheme { light, sepia, dark }

class SMushafReader extends Equatable {
  const SMushafReader({
    this.currentPage = 1,
    this.layout,
    this.status = LoadStatus.idle,
    this.error,
    this.selectedAyah,
    this.multiSelection = const <String>{},
    this.fontScale = 1.0,
    this.theme = ReaderTheme.light,
  });

  final int currentPage;
  final MPageLayout? layout;
  final LoadStatus status;
  final String? error;
  final ParamAyahRef? selectedAyah;
  final Set<String> multiSelection;
  final double fontScale;
  final ReaderTheme theme;

  SMushafReader copyWith({
    int? currentPage,
    MPageLayout? layout,
    LoadStatus? status,
    String? error,
    ParamAyahRef? selectedAyah,
    bool clearSelected = false,
    Set<String>? multiSelection,
    double? fontScale,
    ReaderTheme? theme,
  }) {
    return SMushafReader(
      currentPage: currentPage ?? this.currentPage,
      layout: layout ?? this.layout,
      status: status ?? this.status,
      error: error,
      selectedAyah: clearSelected ? null : (selectedAyah ?? this.selectedAyah),
      multiSelection: multiSelection ?? this.multiSelection,
      fontScale: fontScale ?? this.fontScale,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        layout,
        status,
        error,
        selectedAyah,
        multiSelection,
        fontScale,
        theme,
      ];
}
