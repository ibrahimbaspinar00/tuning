import 'package:flutter/material.dart';

/// Responsive design helper class with standard breakpoints
/// Provides consistent responsive behavior across the app
class ResponsiveHelper {
  // Standard breakpoints
  static const double mobileBreakpoint = 576;
  static const double tabletBreakpoint = 768;
  static const double laptopBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  static const double largeScreenBreakpoint = 1440;

  /// Get screen width from context
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height from context
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < tabletBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is laptop
  static bool isLaptop(BuildContext context) {
    final width = screenWidth(context);
    return width >= laptopBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopBreakpoint;
  }

  /// Check if current screen is large screen
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= largeScreenBreakpoint;
  }

  /// Get responsive value based on screen size
  /// Returns different values for mobile, tablet, and desktop
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeScreen,
  }) {
    if (isLargeScreen(context) && largeScreen != null) {
      return largeScreen;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    final value = responsiveValue<double>(
      context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeScreen: largeScreen ?? 48.0,
    );
    return EdgeInsets.all(value);
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    final value = responsiveValue<double>(
      context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeScreen: largeScreen ?? 48.0,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// Get responsive vertical padding
  static EdgeInsets responsiveVerticalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    final value = responsiveValue<double>(
      context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeScreen: largeScreen ?? 48.0,
    );
    return EdgeInsets.symmetric(vertical: value);
  }

  /// Get responsive font size using clamp-like behavior
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
      largeScreen: largeScreen ?? mobile * 1.3,
    );
  }

  /// Get responsive grid cross axis count
  static int responsiveGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    if (isDesktop(context)) return 3;
    return 4; // Large screen
  }

  /// Get responsive grid cross axis count for product grids
  static int responsiveProductGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 3;
    if (isDesktop(context)) return 4;
    return 5; // Large screen
  }

  /// Get responsive width (percentage based)
  static double responsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    final width = screenWidth(context);
    final percentage = responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile,
      desktop: desktop ?? (tablet ?? mobile),
      largeScreen: largeScreen ?? (desktop ?? tablet ?? mobile),
    );
    return width * percentage;
  }

  /// Get responsive max width (for containers)
  static double responsiveMaxWidth(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile ?? double.infinity,
      tablet: tablet ?? 600.0,
      desktop: desktop ?? 1200.0,
      largeScreen: largeScreen ?? 1400.0,
    );
  }

  /// Get responsive spacing
  static double responsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.25,
      desktop: desktop ?? mobile * 1.5,
      largeScreen: largeScreen ?? mobile * 2.0,
    );
  }

  /// Get responsive border radius
  static double responsiveBorderRadius(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
      largeScreen: largeScreen ?? mobile * 1.3,
    );
  }

  /// Get responsive icon size
  static double responsiveIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
      largeScreen: largeScreen ?? mobile * 1.3,
    );
  }

  /// Get responsive aspect ratio for product cards
  static double responsiveProductAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.85;
    if (isTablet(context)) return 0.62;
    if (isDesktop(context)) return 0.55;
    return 0.5; // Large screen
  }

  /// Get responsive grid spacing
  static double responsiveGridSpacing(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeScreen,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile ?? 12.0,
      tablet: tablet ?? 14.0,
      desktop: desktop ?? 16.0,
      largeScreen: largeScreen ?? 20.0,
    );
  }
}

/// Extension methods for easier responsive access
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isLargeScreen => ResponsiveHelper.isLargeScreen(this);
  
  double get screenWidth => ResponsiveHelper.screenWidth(this);
  double get screenHeight => ResponsiveHelper.screenHeight(this);
  
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeScreen,
  }) => ResponsiveHelper.responsiveValue(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeScreen: largeScreen,
  );
}

