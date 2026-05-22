import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/legal/presentation/widgets/w_markdown_screen.dart';

class LegalModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(LegalRoutes.privacy, child: (_) => const WMarkdownScreen(
          titleKey: 'legal_privacy',
          arAsset: 'assets/legal/privacy_ar.md',
          enAsset: 'assets/legal/privacy_en.md',
        ));
    r.child(LegalRoutes.terms, child: (_) => const WMarkdownScreen(
          titleKey: 'legal_terms',
          arAsset: 'assets/legal/terms_ar.md',
          enAsset: 'assets/legal/terms_en.md',
        ));
    r.child(LegalRoutes.about, child: (_) => const WMarkdownScreen(
          titleKey: 'legal_about',
          arAsset: 'assets/legal/about_ar.md',
          enAsset: 'assets/legal/about_en.md',
        ));
  }
}
