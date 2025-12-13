import 'package:flutter/material.dart';

/// A drop-in wrapper to eliminate bottom overflows in Container-heavy screens.
///
/// Usage:
///   return Scaffold(
///     body: NoOverflow(child: YourColumnOrList()),
///   );
class NoOverflow extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const NoOverflow({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    // Klavye performansı için LayoutBuilder kaldırıldı
    // viewInsets kullanımı gereksiz rebuild'lere neden oluyordu
    return SafeArea(
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.only(bottom: 16),
        physics: const ClampingScrollPhysics(),
        child: child,
      ),
    );
  }
}


