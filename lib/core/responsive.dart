import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return desktop;
    if (width >= 700) return tablet ?? desktop;
    return mobile;
  }
}
