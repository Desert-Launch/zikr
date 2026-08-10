import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';

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
