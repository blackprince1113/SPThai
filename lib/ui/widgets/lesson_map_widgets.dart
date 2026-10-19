import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';

class UnitHeaderCard extends StatelessWidget {
  final String title;
  final String emoji;
  final int completed;
  final int total;

  const UnitHeaderCard({
    super.key,
    required this.title,
    this.emoji = '🎯',
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.03 : 0.2,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$completed/$total",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapNode extends StatelessWidget {
  final LessonPlan plan;
  final int completed;
  final int total;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isLocked;
  final double alignment;

  const MapNode({
    super.key,
    required this.plan,
    required this.completed,
    required this.total,
    required this.onTap,
    this.onLongPress,
    this.isLocked = false,
    this.alignment = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCompleted = total > 0 && completed == total;
    final bool isActive = !isCompleted && !isLocked;

    int stars = 0;
    if (total > 0 && completed > 0) {
      if (completed == total) {
        stars = 3;
      } else if (completed >= total / 2) {
        stars = 2;
      } else {
        stars = 1;
      }
    }

    Color bgColor = theme.cardColor;
    BoxBorder? border = Border.all(
      color: theme.dividerColor.withValues(alpha: 0.2),
      width: 2,
    );

    if (isCompleted) {
      bgColor = theme.cardColor;
      border = Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
        width: 2,
      );
    } else if (isActive) {
      bgColor = theme.cardColor;
      border = Border.all(color: theme.colorScheme.primary, width: 4);
    }

    return Align(
      alignment: Alignment(alignment, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isLocked ? null : onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(28),
                    border: border,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      plan.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (stars > 0)
                  Positioned(
                    top: -15,
                    child: Row(
                      children: List.generate(3, (index) {
                        return Icon(
                          Icons.star,
                          color: index < stars
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.2),
                          size: 16,
                        );
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                plan.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  MapPathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (points.isEmpty) return;

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];

      final controlPoint1 = Offset(p0.dx, p0.dy + (p1.dy - p0.dy) * 0.5);
      final controlPoint2 = Offset(p1.dx, p0.dy + (p1.dy - p0.dy) * 0.5);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MapPathPainter oldDelegate) => true;
}
