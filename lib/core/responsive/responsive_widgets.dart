import 'package:flutter/material.dart';
import 'package:quran/core/responsive/responsive_helpers.dart';

/// Generic widget that renders different layouts for phone vs tablet
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget tablet;
  final double breakpoint;

  const ResponsiveLayout({super.key, required this.phone, required this.tablet, this.breakpoint = 600});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= breakpoint ? tablet : phone;
      },
    );
  }
}

/// Wraps content with max width on tablets — prevents stretching
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentConstraint({super.key, required this.child, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Constrains child to a comfortable max width and centers it.
/// USE THIS ON EVERY SCREEN BODY to prevent full-width stretching on tablets.
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool useWideWidth;
  final EdgeInsetsGeometry? padding;

  const ContentContainer({super.key, required this.child, this.maxWidth, this.useWideWidth = false, this.padding});

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ??
        (useWideWidth ? AppResponsive.maxWideContentWidth(context) : AppResponsive.maxContentWidth(context));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Wraps screen body with responsive side padding + max-width constraint.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final bool useWideWidth;
  final double? maxWidth;

  const ResponsiveBody({super.key, required this.child, this.useWideWidth = false, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppResponsive.screenPadding(context),
      child: ContentContainer(useWideWidth: useWideWidth, maxWidth: maxWidth, child: child),
    );
  }
}

/// Adaptive grid that auto-calculates columns based on available width
class AdaptiveGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  AdaptiveGridDelegate({
    required double availableWidth,
    double minItemWidth = 160,
    super.childAspectRatio = 1.0,
    super.crossAxisSpacing = 8,
    super.mainAxisSpacing = 8,
  }) : super(crossAxisCount: (availableWidth / minItemWidth).floor().clamp(1, 6));
}

/// Adaptive grid widget that auto-calculates column count.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.spacing = 12,
    this.childAspectRatio = 1.0,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor().clamp(1, 6);
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          physics: physics,
          shrinkWrap: shrinkWrap,
          children: children,
        );
      },
    );
  }
}
