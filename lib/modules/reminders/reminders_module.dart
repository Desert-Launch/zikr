import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/reminders/presentation/screens/sn_reminder_form.dart';
import 'package:quran/modules/reminders/presentation/screens/sn_reminders.dart';

class RemindersModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(RemindersRoutes.list, child: (_) => const SNReminders());
    r.child(RemindersRoutes.form, child: (_) {
      final id = r.args.queryParams['id'];
      return SNReminderForm(reminderId: id);
    });
  }
}
