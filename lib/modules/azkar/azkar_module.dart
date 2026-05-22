import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/screens/sn_azkar_favorites.dart';
import 'package:quran/modules/azkar/presentation/screens/sn_azkar_home.dart';
import 'package:quran/modules/azkar/presentation/screens/sn_azkar_player.dart';

class AzkarModule extends Module {
  @override
  void binds(Injector i) {
    // Per-screen cubit (factory). Boxes + DS live in AppModule.
    i.add<CBAzkarSession>(
      () => CBAzkarSession(
        local: Modular.get<DSLocalAzkar>(),
        progress: Modular.get<BoxAzkarProgress>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(AzkarRoutes.home, child: (_) => const SNAzkarHome());
    r.child(AzkarRoutes.player, child: (_) {
      final categoryId = r.args.queryParams['category'] ?? 'morning';
      return SNAzkarPlayer(categoryId: categoryId);
    });
    r.child(AzkarRoutes.favorites, child: (_) => const SNAzkarFavorites());
  }
}

