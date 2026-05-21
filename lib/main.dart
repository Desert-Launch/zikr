import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/routes/app_module.dart';
import 'package:quran/core/theme/app_themes.dart';
import 'package:quran/core/theme/theme_manager.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/data/models/m_reciter_pref.dart';
import 'package:quran/modules/quran/data/sources/local/quran_hive_registrar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.init();
  AppLogger.info('Boot start', tag: 'main');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await LocalizeAndTranslate.init(
    supportedLocales: const [Locale('ar'), Locale('en')],
    defaultType: LocalizationDefaultType.asDefined,
    assetLoader: const AssetLoaderRootBundleJson('assets/lang/'),
  );

  // localize_and_translate initialises the *legacy* hive_flutter — that's a
  // different instance from hive_ce. We must initialise hive_ce separately
  // before opening any of our own boxes.
  await Hive.initFlutter();
  QuranHiveRegistrar.registerAdapters();

  // Eagerly open Hive boxes so the first reads in cubits aren't async.
  await Hive.openBox<MBookmark>('quran_bookmarks');
  await Hive.openBox<MLastRead>('quran_last_read');
  await Hive.openBox<MReciterPref>('quran_reciter_pref');
  await Hive.openBox<MDownloadTask>('quran_download_tasks');

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.app.quran.audio',
    androidNotificationChannelName: 'Quran Recitation',
    androidNotificationOngoing: true,
  );

  AppLogger.info('Boot done — runApp', tag: 'main');
  runApp(
    ModularApp(module: AppModule(), child: const LocalizedApp(child: _Root())),
  );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: Modular.get<ThemeManager>(),
          builder: (context, _) {
            final themeManager = Modular.get<ThemeManager>();
            return MaterialApp.router(
              title: 'قرآن',
              debugShowCheckedModeBanner: false,
              theme: AppThemes.light,
              darkTheme: AppThemes.dark,
              themeMode: themeManager.themeMode,
              routerConfig: Modular.routerConfig,
              localizationsDelegates: LocalizeAndTranslate.delegates,
              supportedLocales: LocalizeAndTranslate.getLocals(),
            );
          },
        );
      },
    );
  }
}
