import 'package:flutter/material.dart';

/// Breakpoint helper untuk responsive layout.
/// Desktop: >= 768px, Mobile: < 768px
class Responsive {
  static const double mobileBreakpoint = 768;

  /// Gunakan ini di luar LayoutBuilder (misal di padding, header)
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? double.infinity;
    return width < mobileBreakpoint;
  }

  static bool isDesktop(BuildContext context) => !isMobile(context);

  /// Gunakan ini di dalam LayoutBuilder — lebih aman di desktop/Windows
  static bool isMobileConstraint(BoxConstraints constraints) =>
      constraints.maxWidth < mobileBreakpoint;

  /// Padding konten: 32 di desktop, 16 di mobile
  static EdgeInsets contentPadding(BuildContext context) =>
      isMobile(context)
          ? const EdgeInsets.all(16)
          : const EdgeInsets.all(32);

  /// Jumlah kolom grid: [mobile, desktop]
  static int gridColumns(BuildContext context, {int mobile = 2, int desktop = 4}) =>
      isMobile(context) ? mobile : desktop;
}
