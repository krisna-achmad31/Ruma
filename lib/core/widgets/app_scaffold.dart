import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_tab_bar.dart';

/// Latar gradasi lembut yang jadi dasar efek kaca di semua layar.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.background)),
        const _Blob(alignment: Alignment(-0.9, -0.95), color: AppColors.blobMint, widthFactor: 1.4, heightFactor: 0.7),
        const _Blob(alignment: Alignment(0.95, -0.05), color: AppColors.blobPeach, widthFactor: 1.3, heightFactor: 0.6),
        const _Blob(alignment: Alignment(-0.7, 0.95), color: AppColors.blobLilac, widthFactor: 1.3, heightFactor: 0.5),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double widthFactor;
  final double heightFactor;

  const _Blob({required this.alignment, required this.color, required this.widthFactor, required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: size.width * widthFactor,
            height: size.height * heightFactor,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kerangka layar: latar gradasi, konten bisa di-scroll, dan tab bar kaca opsional.
class AppScaffold extends StatelessWidget {
  final List<Widget> children;
  final AppTab? tab;
  final Widget? header;
  final Widget? bottom;
  final double gap;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;

  const AppScaffold({
    super.key,
    required this.children,
    this.tab,
    this.header,
    this.bottom,
    this.gap = 24,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSpace = tab != null ? 100.0 : 0.0;
    Widget scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: padding.copyWith(bottom: padding.bottom + bottomSpace),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: gap, children: children),
    );
    if (onRefresh != null) scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  if (header != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: header),
                  Expanded(child: scroll),
                  if (bottom != null)
                    SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: bottom)),
                ],
              ),
              if (tab != null) Positioned(left: 0, right: 0, bottom: 0, child: AppTabBar(current: tab!)),
            ],
          ),
        ),
      ),
    );
  }
}
