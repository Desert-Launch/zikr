import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/widgets/w_loading_overlay.dart';

class WSharedScaffold extends StatefulWidget {
  const WSharedScaffold({
    required this.body,
    this.scaffoldKey,
    this.resizeToAvoidBottomInset,
    this.appBar,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding,
    this.withSafeArea = true,
    this.isScreenLoading = false,
    this.loadingMessage,
    this.backgroundColor,
    super.key,
  });

  final Widget body;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool withSafeArea;
  final bool? resizeToAvoidBottomInset;
  final bool? isScreenLoading;
  final String? loadingMessage;
  final Widget? appBar;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  State<WSharedScaffold> createState() => _WSharedScaffoldState();
}

class _WSharedScaffoldState extends State<WSharedScaffold> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              color: widget.backgroundColor ?? AppColors.secondScaffoldBackground,
              width: context.width,
              height: context.height,
            ),
            Scaffold(
              key: widget.scaffoldKey,
              resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset ?? true,
              backgroundColor: Colors.transparent,
              appBar: widget.appBar == null
                  ? null
                  : AppBar(
                      title: widget.appBar,
                      leading: const SizedBox(),
                      leadingWidth: 0,
                      backgroundColor: Colors.transparent,
                      forceMaterialTransparency: true,
                    ),
              body: SafeArea(
                top: widget.withSafeArea,
                bottom: widget.withSafeArea,
                right: widget.withSafeArea,
                left: widget.withSafeArea,
                child: Container(
                  padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 0.h),
                  child: widget.body,
                ),
              ),
              floatingActionButton: widget.floatingActionButton,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              bottomSheet: widget.bottomSheet,
              bottomNavigationBar: widget.bottomNavigationBar,
            ),
            WLoadingOverlay(show: widget.isScreenLoading ?? false, message: widget.loadingMessage),
          ],
        ),
      ),
    );
  }
}
