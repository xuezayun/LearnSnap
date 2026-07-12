import 'package:flutter/material.dart';

const double _tabletBreakpoint = 600;

bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide >= _tabletBreakpoint;
}

double contentMaxWidth(BuildContext context) {
  return isTablet(context) ? 720 : double.infinity;
}

double formMaxWidth(BuildContext context) {
  return isTablet(context) ? 480 : double.infinity;
}

double pagePadding(BuildContext context) {
  return isTablet(context) ? 36 : 24;
}

double mediaThumbSize(BuildContext context) {
  return isTablet(context) ? 150 : 100;
}

double primaryButtonHeight(BuildContext context) {
  return isTablet(context) ? 52 : 48;
}

double recordButtonSize(BuildContext context) {
  return isTablet(context) ? 96 : 76;
}

int mediaGridColumnCount(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final thumb = mediaThumbSize(context);
  final padding = pagePadding(context);
  final available = width - padding * 2;
  if (isTablet(context)) {
    return (available / (thumb + 16)).floor().clamp(3, 5);
  }
  return (available / (thumb + 12)).floor().clamp(2, 4);
}

SliverGridDelegate mediaGridDelegate(BuildContext context) {
  final columns = mediaGridColumnCount(context);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 1,
  );
}

class AdaptiveBody extends StatelessWidget {
  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? contentMaxWidth(context);
    final resolvedPadding = padding ?? EdgeInsets.all(pagePadding(context));
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: Padding(
          padding: resolvedPadding,
          child: child,
        ),
      ),
    );
  }
}

class AdaptiveBottomBar extends StatelessWidget {
  const AdaptiveBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.all(pagePadding(context)),
      child: AdaptiveBody(
        maxWidth: contentMaxWidth(context),
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
