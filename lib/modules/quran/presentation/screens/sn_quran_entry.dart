import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_entry.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_entry.dart';

/// Gate screen for `/quran/entry` — the door Home knocks on.
///
/// It renders nothing but the index canvas for the frame or two the last-read
/// lookup takes, then *replaces itself* with the real destination. Replacing
/// rather than pushing is the point: the gate never lands in the back stack, so
/// Back from the reader (or the index) goes straight Home instead of bouncing
/// through a screen the user never saw.
class SNQuranEntry extends StatefulWidget {
  const SNQuranEntry({super.key});

  @override
  State<SNQuranEntry> createState() => _SNQuranEntryState();
}

class _SNQuranEntryState extends State<SNQuranEntry> {
  /// Matches [SNSurahList]'s canvas, so a first-visit gate reads as the index
  /// already painting rather than as a flash of a different screen.
  static const _canvas = Color(0xFFF8F7F4);

  late final CBQuranEntry _cubit = Modular.get<CBQuranEntry>();

  /// Guards against a second navigation if the state settles twice.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Kicked off after the first frame so the replace lands on a route that has
    // finished being pushed — a Hive get can settle inside the same frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.resolve();
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onResolved(BuildContext context, SQuranEntry state) {
    if (_navigated || !mounted) return;
    if (state.target == QuranEntryTarget.resolving) return;
    final page = state.page;
    _navigated = true;
    Modular.to.pushReplacementNamed(
      state.target == QuranEntryTarget.reader && page != null
          ? QuranRoutes.readerFromPage(page)
          : QuranRoutes.fullSurahList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CBQuranEntry, SQuranEntry>(
      bloc: _cubit,
      listener: _onResolved,
      child: const WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: SizedBox.shrink(),
      ),
    );
  }
}
