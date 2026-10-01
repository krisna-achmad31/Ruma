import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_brand.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/l10n/app_locale.dart';

/// Splash kolase 3D: ikon rumah di tengah, dikelilingi ikon 3D yang melayang pelan.
/// Pindah ke Onboarding atau Hari ini setelah status login diketahui.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  bool _minTimePassed = false;
  bool _navigated = false;
  Timer? _timer;

  // (ikon, posisi x relatif, posisi y relatif, ukuran, kemiringan derajat)
  static const _floating = [
    ('money_bag', 0.09, 0.18, 72.0, -12.0),
    ('red_heart', 0.69, 0.15, 64.0, 10.0),
    ('sparkles', 0.08, 0.33, 44.0, -6.0),
    ('coin', 0.77, 0.30, 48.0, 14.0),
    ('spiral_calendar', 0.10, 0.66, 64.0, 8.0),
    ('clipboard', 0.72, 0.70, 70.0, -8.0),
    ('shopping_cart', 0.44, 0.82, 56.0, 4.0),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      _minTimePassed = true;
      _maybeGo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _float.dispose();
    super.dispose();
  }

  void _maybeGo() {
    if (!mounted || _navigated || !_minTimePassed) return;
    final auth = context.read<AuthViewModel>();
    if (auth.status == AuthStatus.unknown) return;
    _navigated = true;
    context.go(auth.status == AuthStatus.authenticated ? (auth.pendingInvite ? '/invite' : '/') : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGo());
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: AppBackground(
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_float.value);
            return Stack(
              children: [
                for (int i = 0; i < _floating.length; i++)
                  Positioned(
                    left: size.width * _floating[i].$2,
                    top: size.height * _floating[i].$3 + (i.isEven ? -6 : 6) * (t * 2 - 1),
                    child: Transform.rotate(
                      angle: -_floating[i].$5 * math.pi / 180,
                      child: _Tile(icon: _floating[i].$1, size: _floating[i].$4),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 14,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F5446), Color(0xFF3D8270)]),
                          boxShadow: const [BoxShadow(color: Color(0x552C6B5A), blurRadius: 36, offset: Offset(0, 16))],
                        ),
                        child: Image.asset('assets/icons3d/house.png', width: 72, height: 72),
                      ),
                      Text(AppBrand.name, style: AppText.display(32, letterSpacing: -0.9)),
                      Text(tr('Urusan, uang, dan kita. Satu rumah.'), style: AppText.body(14, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String icon;
  final double size;

  const _Tile({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    final box = size + 28;
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(box * 0.32),
        border: Border.all(color: AppColors.glassEdge),
        boxShadow: const [BoxShadow(color: Color(0x1A15201D), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Image.asset('assets/icons3d/$icon.png', width: size, height: size),
    );
  }
}
