import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium glassmorphism card widget with Apple-inspired design
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? Colors.white.withOpacity(opacity)
        : Colors.white.withOpacity(opacity + 0.3);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color ?? defaultColor,
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                    width: 1.5,
                  ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.05 : 0.2),
                  Colors.white.withOpacity(isDark ? 0.02 : 0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated gradient card with shimmer effect
class GradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool animated;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.margin,
    this.borderRadius,
    this.animated = true,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        child: widget.animated
            ? AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + _animation.value * 2, -1.0),
                        end: Alignment(1.0 - _animation.value * 2, 1.0),
                        colors: widget.gradientColors,
                      ),
                    ),
                    child: widget.child,
                  );
                },
              )
            : Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors,
                  ),
                ),
                child: widget.child,
              ),
      ),
    );
  }
}

/// Neumorphic card with subtle depth
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool pressed;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E5EC);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: pressed
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : const Color(0xFFA3B1C6),
                  offset: const Offset(2, 2),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                  offset: const Offset(-2, -2),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : const Color(0xFFA3B1C6),
                  offset: const Offset(8, 8),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  offset: const Offset(-8, -8),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Glowing card with luminous border
class GlowingCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const GlowingCard({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 20,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.5),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.3),
            blurRadius: glowRadius * 2,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          border: Border.all(color: glowColor.withOpacity(0.5), width: 2),
        ),
        child: child,
      ),
    );
  }
}

/// Premium button with glass effect
class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).primaryColor).withOpacity(
                  0.2,
                ),
                borderRadius: borderRadius ?? BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
