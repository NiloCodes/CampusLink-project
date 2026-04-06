// lib/widgets/campuslink_logo.dart
//
// PURPOSE: Renders the CampusLink logo entirely in Dart code using
// CustomPainter. Zero asset files needed — scales perfectly at every
// screen density without blurring.
//
// ARCHITECTURAL NOTE (for your defense):
// CustomPainter uses Flutter's Canvas API — the same low-level drawing
// system used by Flutter itself to render all widgets. This is the most
// performant way to render vector graphics in Flutter because:
//   1. No file I/O — the logo is drawn directly to the GPU canvas
//   2. Resolution independent — crisp on every screen density
//   3. No external packages required
//
// USAGE EXAMPLES:
//
//   // Standard size (welcome screen logo card):
//   const CampusLinkLogo(size: 64)
//
//   // Large (splash screen):
//   const CampusLinkLogo(size: 120)
//
//   // Small (app bar):
//   const CampusLinkLogo(size: 32, variant: LogoVariant.markOnly)
//
//   // Full lockup with wordmark below:
//   const CampusLinkLogo(size: 80, variant: LogoVariant.withWordmark)

import 'package:flutter/material.dart';
import '../core/constants.dart';

// Controls which version of the logo is rendered
enum LogoVariant {
  markOnly, // just the icon mark — used in app bar, small spaces
  withWordmark, // icon + "CampusLink" text below — used on welcome screen
}

// Controls the color scheme of the logo
enum LogoScheme {
  onLight, // dark navy mark on transparent — used on white/grey backgrounds
  onDark, // white mark on transparent — used on dark/navy backgrounds
}

class CampusLinkLogo extends StatelessWidget {
  final double size;
  final LogoVariant variant;
  final LogoScheme scheme;

  const CampusLinkLogo({
    super.key,
    this.size = 64,
    this.variant = LogoVariant.markOnly,
    this.scheme = LogoScheme.onLight,
  });

  @override
  Widget build(BuildContext context) {
    // If withWordmark, add vertical space below the mark for the text
    final totalHeight =
        variant == LogoVariant.withWordmark ? size + (size * 0.45) : size;

    return SizedBox(
      width: size,
      height: totalHeight,
      child: CustomPaint(
        painter: _LogoPainter(
          size: size,
          variant: variant,
          scheme: scheme,
        ),
      ),
    );
  }
}

// =============================================================================
// THE PAINTER
// =============================================================================
// This class does the actual drawing. Flutter calls paint() whenever the
// widget needs to be rendered or re-rendered.
//
// THE MARK CONCEPT:
// Two circles (nodes) connected by a horizontal line — representing the
// peer-to-peer connection between verified UCC students. A small shield
// checkmark sits at the center of the link, representing the trust/escrow
// layer. The whole mark is enclosed in a rounded square container.

class _LogoPainter extends CustomPainter {
  final double size;
  final LogoVariant variant;
  final LogoScheme scheme;

  _LogoPainter({
    required this.size,
    required this.variant,
    required this.scheme,
  });

  // Primary colors based on scheme
  Color get _primary =>
      scheme == LogoScheme.onLight ? AppColors.primary : Colors.white;

  // ignore: unused_element
  Color get _accent =>
      scheme == LogoScheme.onLight ? AppColors.accent : Colors.white70;

  Color get _background => scheme == LogoScheme.onLight
      ? AppColors.backgroundWhite
      : AppColors.primary;

  // ignore: unused_element
  Color get _nodeInner => scheme == LogoScheme.onLight
      ? AppColors.backgroundWhite
      : AppColors.primary;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // All measurements are relative to `size` so the logo scales correctly
    // at any size — 32px, 64px, 120px — without any hardcoded pixel values.

    final double s = size;
    final double cx = s / 2; // center x of the mark
    final double cy = s / 2; // center y of the mark

    // ── BACKGROUND ROUNDED SQUARE ──────────────────────────────────────────
    // The navy rounded square container that holds the mark.
    final bgPaint = Paint()
      ..color = _background
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.22), // proportional corner radius
    );
    canvas.drawRRect(bgRect, bgPaint);

    // ── NODE MEASUREMENTS ──────────────────────────────────────────────────
    final double nodeRadius = s * 0.155; // outer circle radius
    final double nodeInnerR = s * 0.085; // inner filled circle
    final double nodeSeparation = s * 0.28; // distance from center to each node
    final double leftX = cx - nodeSeparation;
    final double rightX = cx + nodeSeparation;

    // ── CONNECTING LINE ────────────────────────────────────────────────────
    // Horizontal line between the two nodes
    // ignore: unused_local_variable
    final linePaint = Paint()
      ..color = _primary.withValues(
          alpha: scheme == LogoScheme.onLight
              ? 0.0
              : 0.4) // invisible on light (bg handles it)
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;

    final connectorPaint = Paint()
      ..color = scheme == LogoScheme.onLight
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftX + nodeRadius * 0.6, cy),
      Offset(rightX - nodeRadius * 0.6, cy),
      connectorPaint,
    );

    // ── LEFT NODE ──────────────────────────────────────────────────────────
    // Outer glow ring
    final nodeGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(leftX, cy), nodeRadius, nodeGlowPaint);

    // Outer ring stroke
    final nodeRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025;
    canvas.drawCircle(Offset(leftX, cy), nodeRadius, nodeRingPaint);

    // Inner filled circle
    final nodeInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(leftX, cy), nodeInnerR, nodeInnerPaint);

    // Center dot (the "pupil" — represents a person)
    final nodeDotPaint = Paint()
      ..color = _background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(leftX, cy), nodeInnerR * 0.42, nodeDotPaint);

    // ── RIGHT NODE ─────────────────────────────────────────────────────────
    // Mirror of left node
    canvas.drawCircle(Offset(rightX, cy), nodeRadius, nodeGlowPaint);
    canvas.drawCircle(Offset(rightX, cy), nodeRadius, nodeRingPaint);
    canvas.drawCircle(Offset(rightX, cy), nodeInnerR, nodeInnerPaint);
    canvas.drawCircle(Offset(rightX, cy), nodeInnerR * 0.42, nodeDotPaint);

    // ── CENTER SHIELD (trust / escrow layer) ───────────────────────────────
    // A small shield shape at the center of the connecting line
    // This is the key differentiator — it visually represents the
    // trust/escrow mechanism that makes CampusLink unique.
    _drawShield(canvas, Offset(cx, cy), s * 0.13);

    // ── WORDMARK (optional) ────────────────────────────────────────────────
    if (variant == LogoVariant.withWordmark) {
      _drawWordmark(canvas, s);
    }
  }

  // Draws a shield shape centered at [center] with given [radius]
  void _drawShield(Canvas canvas, Offset center, double radius) {
    final shieldPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final double r = radius;
    final double x = center.dx;
    final double y = center.dy;

    // Shield outline path — starts at top center, curves down to a point
    path.moveTo(x, y - r);
    path.cubicTo(
      x + r * 0.9,
      y - r,
      x + r * 1.1,
      y - r * 0.3,
      x + r * 1.1,
      y + r * 0.1,
    );
    path.cubicTo(
      x + r * 1.1,
      y + r * 0.7,
      x + r * 0.5,
      y + r * 1.1,
      x,
      y + r * 1.3,
    );
    path.cubicTo(
      x - r * 0.5,
      y + r * 1.1,
      x - r * 1.1,
      y + r * 0.7,
      x - r * 1.1,
      y + r * 0.1,
    );
    path.cubicTo(
      x - r * 1.1,
      y - r * 0.3,
      x - r * 0.9,
      y - r,
      x,
      y - r,
    );
    path.close();

    canvas.drawPath(path, shieldPaint);

    // Checkmark inside the shield
    final checkPaint = Paint()
      ..color = _background
      ..strokeWidth = r * 0.38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final checkPath = Path();
    checkPath.moveTo(x - r * 0.45, y + r * 0.15);
    checkPath.lineTo(x - r * 0.1, y + r * 0.55);
    checkPath.lineTo(x + r * 0.55, y - r * 0.25);

    canvas.drawPath(checkPath, checkPaint);
  }

  // Draws "CampusLink" wordmark below the mark
  void _drawWordmark(Canvas canvas, double s) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Campus',
            style: TextStyle(
              fontSize: s * 0.22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Link',
            style: TextStyle(
              fontSize: s * 0.22,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center the wordmark horizontally below the mark
    final double textX = (s - textPainter.width) / 2;
    final double textY = s + (s * 0.08); // small gap below the mark

    textPainter.paint(canvas, Offset(textX, textY));
  }

  // shouldRepaint returns false because the logo never changes at runtime —
  // no animation, no state. Flutter skips unnecessary repaints.
  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.variant != variant ||
      oldDelegate.scheme != scheme;
}
