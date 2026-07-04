import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/live/data/datasources/remote/ds_remote_live.dart';
import 'package:quran/modules/live/data/repos/r_impl_live.dart';
import 'package:quran/modules/live/domain/repos/r_live.dart';
import 'package:quran/modules/live/domain/usecases/uc_resolve_live_video.dart';
import 'package:quran/modules/live/domain/entities/e_live_channel.dart';
import 'package:quran/modules/live/presentation/cubits/cb_live.dart';
import 'package:quran/modules/live/presentation/screens/sn_live.dart';
import 'package:quran/modules/live/presentation/screens/sn_live_picker.dart';

/// Haramain live-broadcast module. Embeds the official KSA YouTube channels
/// (see [ELiveChannel]) and resolves each channel's CURRENT live video at
/// runtime — the only data it needs is that lookup (remote owns its own Dio).
class LiveModule extends Module {
  @override
  void binds(Injector i) {
    // Data source (owns its own Dio → no BaseDio dependency).
    i.add<DSRemoteLive>(DSRemoteLive.new);

    // Repo (interface → impl).
    i.add<RLive>(() => RImplLive(remote: i.get<DSRemoteLive>()));

    // Use case.
    i.add(() => UCResolveLiveVideo(i.get<RLive>()));

    // Per-screen cubit.
    i.add<CBLive>(() => CBLive(i.get<UCResolveLiveVideo>()));
  }

  @override
  void routes(RouteManager r) {
    // Channel picker first, then the player for the chosen channel.
    r.child(LiveRoutes.home, child: (_) => const SNLivePicker());
    r.child(
      LiveRoutes.player,
      child: (_) => SNLive(
        channel: ELiveChannel.byId(r.args.queryParams['channel'] ?? ELiveChannel.makkah.id),
      ),
    );
  }
}
