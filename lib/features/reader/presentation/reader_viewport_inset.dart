import 'package:flutter/material.dart';

/// Applies exactly ONE status-bar top inset to the reader viewport.
///
/// The reader Scaffold uses `extendBodyBehindAppBar: true`, so the body starts
/// at the screen top whether the reader bars are shown or hidden. Crucially,
/// that flag also inflates the body's own `MediaQuery.padding.top` by the app
/// bar height while the bar is visible — so the inset must be measured ABOVE
/// the Scaffold and passed in as [topInset]. Insetting the viewport by that
/// (constant) status-bar height here, and nowhere else, keeps its top offset
/// fixed as the bars toggle, instead of snapping up when the AppBar (which
/// carries its own inset) disappears.
class ReaderViewportInset extends StatelessWidget {
  const ReaderViewportInset({
    super.key,
    required this.topInset,
    required this.child,
  });

  final double topInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: child,
    );
  }
}
