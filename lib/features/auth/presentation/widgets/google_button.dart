import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';

/// Tombol "Masuk/Daftar dengan Google" bergaya kaca dengan logo G berwarna.
class GoogleButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const GoogleButton({super.key, required this.label, this.loading = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.hairline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onPressed,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              if (loading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.jade))
              else
                const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
              Text(label, style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;

    canvas.drawArc(rect, deg(-40), deg(-100), false, p(const Color(0xFFEA4335)));
    canvas.drawArc(rect, deg(-140), deg(-90), false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, deg(130), deg(-90), false, p(const Color(0xFF34A853)));
    canvas.drawArc(rect, deg(40), deg(-40), false, p(const Color(0xFF4285F4)));
    // Palang horizontal biru khas huruf G.
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2, size.width / 2, stroke), bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
