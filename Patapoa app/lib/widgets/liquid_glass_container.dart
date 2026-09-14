import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final double borderWidth;
  final Gradient? gradient;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 32,
    this.blur = 20,
    this.opacity = 0.15,
    this.color,
    this.padding,
    this.boxShadow,
    this.borderWidth = 1.5,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: (color ?? Colors.white).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: -5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              // Subtle Inner Shine/Gradient
              Container(
                padding: padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: gradient ?? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (color ?? Colors.white).withValues(alpha: opacity + 0.1),
                      (color ?? Colors.white).withValues(alpha: opacity),
                      (color ?? Colors.white).withValues(alpha: opacity - 0.05),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: (color ?? Colors.white).withValues(alpha: 0.3),
                    width: borderWidth,
                  ),
                ),
                child: child,
              ),
              // Diagonal High-Gloss Shine
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedLiquidBackground extends StatefulWidget {
  final Widget child;
  const AnimatedLiquidBackground({super.key, required this.child});

  @override
  State<AnimatedLiquidBackground> createState() => _AnimatedLiquidBackgroundState();
}

class _AnimatedLiquidBackgroundState extends State<AnimatedLiquidBackground> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: LiquidPainter(progress: _controller.value),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double progress;
  LiquidPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Emerald & Teal Tones for the Stunning Original Aesthetic
    final paint1 = Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    final paint2 = Paint()..color = const Color(0xFF0D9488).withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    final paint3 = Paint()..color = const Color(0xFF14B8A6).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Blob 1: Top Left
    final center1 = Offset(
      size.width * 0.1 + (size.width * 0.15 * progress), 
      size.height * 0.2 + (size.height * 0.1 * progress)
    );
    canvas.drawCircle(center1, 200, paint1);

    // Blob 2: Bottom Right
    final center2 = Offset(
      size.width * 0.9 - (size.width * 0.2 * progress), 
      size.height * 0.8 - (size.height * 0.15 * progress)
    );
    canvas.drawCircle(center2, 250, paint2);

    // Blob 3: Center Pulsing
    final center3 = Offset(
      size.width * 0.5, 
      size.height * 0.5 + (size.height * 0.25 * (progress - 0.5).abs())
    );
    canvas.drawCircle(center3, 220, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
