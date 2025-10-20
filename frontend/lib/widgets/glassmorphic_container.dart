import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final double blurStrength;
  final Color? backgroundColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.blurStrength = 10.0,
    this.backgroundColor,
    this.border,
    this.padding,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shape == BoxShape.rectangle
          ? (borderRadius ?? BorderRadius.circular(16.0))
          : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          width: width,
          height: height,
          alignment: alignment,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.surface.withOpacity(0.2),
            borderRadius: shape == BoxShape.rectangle
                ? (borderRadius ?? BorderRadius.circular(16.0))
                : null,
            shape: shape,
            border: border ??
                Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  width: 1.0,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
