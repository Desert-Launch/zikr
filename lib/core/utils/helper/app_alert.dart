import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/widgets/w_in_app_notification.dart';

/// App-wide toasts. These replace `ScaffoldMessenger.showSnackBar` everywhere —
/// they need no `BuildContext`, so they survive a popped route or a sheet that
/// closes before the async work finishes.
///
/// Showing a toast without a context requires the app to be wrapped in a
/// `ToastificationWrapper` (see `main.dart`).
class AppAlert {
  /// Bottom-centred like the snackbars these replaced. Centre alignment is
  /// direction-agnostic, so it lands identically in RTL and LTR.
  static const _alignment = Alignment.bottomCenter;

  /// The in-app twin of a scheduled system notification: slides down from the
  /// top, holds for three seconds, then leaves.
  ///
  /// Top-centred rather than bottom-centred so it reads as a notification
  /// arriving from the status bar instead of as feedback on something the user
  /// just did — and so it never lands on top of a bottom sheet's controls.
  /// Toastification's default transition slides from whichever edge the
  /// alignment names, so top-centre IS the slide-down.
  ///
  /// Fired by `InAppNotificationWatcher`; see it for how the moment is known.
  static void notification({
    required String title,
    required String body,
    String payloadType = '',
    VoidCallback? onTap,
  }) {
    toastification.showCustom(
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 350),
      builder: (_, item) => WInAppNotification(
        title: title,
        body: body,
        payloadType: payloadType,
        // Dismiss before routing: the banner lives in the Navigator's overlay,
        // so leaving it up while the tap pushes a route would park it over the
        // screen it just opened.
        onTap: onTap == null
            ? null
            : () {
                toastification.dismiss(item);
                onTap();
              },
      ),
    );
  }

  static void success(String text) {
    toastification.show(
      alignment: _alignment,
      title: Text(text, style: TextStyle(fontSize: 14.sp), maxLines: 2),
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        color: Color(0xff00FF2E),
        linearMinHeight: 1,
        linearTrackColor: Color(0xffced4da),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: false,
      dragToClose: true,
      applyBlurEffect: true,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      primaryColor: const Color(0xff00FF2E),
      borderRadius: BorderRadius.circular(12.rCapped(14)),
      backgroundColor: Colors.white,
    );
  }

  static void error(String text) {
    toastification.show(
      alignment: _alignment,
      title: Text(text, style: TextStyle(fontSize: 14.sp), maxLines: 2),
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        color: Color(0xffFF002E),
        linearMinHeight: 1,
        linearTrackColor: Color(0xffced4da),
      ),
      closeOnClick: false,
      pauseOnHover: false,
      dragToClose: true,
      applyBlurEffect: true,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      primaryColor: const Color(0xffFF002E),
      borderRadius: BorderRadius.circular(12.rCapped(14)),
      backgroundColor: Colors.white,
    );
  }
}
