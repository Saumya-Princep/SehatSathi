import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ambulance.dart';

class AmbulanceTrackingCard extends StatefulWidget {
  final Ambulance ambulance;
  final VoidCallback onCancel;

  const AmbulanceTrackingCard({
    Key? key,
    required this.ambulance,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AmbulanceTrackingCard> createState() => _AmbulanceTrackingCardState();
}

class _AmbulanceTrackingCardState extends State<AmbulanceTrackingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _etaMinutes = 15.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Randomize initial mock ETA between 8 and 18 minutes
    _etaMinutes = 8.0 + Random().nextDouble() * 10;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Slowly reduce ETA over time to simulate approach
    final currentEta = max(2.0, _etaMinutes - (_controller.value * 0.1));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shadowColor: theme.colorScheme.error.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.error.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2C1E1E), const Color(0xFF1E1E1E)]
                : [const Color(0xFFFFEBEE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.airport_shuttle,
                    color: theme.colorScheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambulance Dispatched',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        'Emergency Response Active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Vehicle', widget.ambulance.vehicleNumber, Icons.directions_car),
                      const SizedBox(height: 12),
                      _buildInfoRow('Driver Contact', '+91 98765 43210', Icons.phone),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'ETA',
                        '${currentEta.toStringAsFixed(1)} mins away',
                        Icons.hourglass_bottom,
                        valueColor: theme.colorScheme.error,
                        valueWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: CustomPaint(
                            painter: RadarPainter(
                              animationVal: _controller.value,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel Request'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.error.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling ambulance dispatch helpline...')),
                      );
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call Helpline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor, FontWeight? valueWeight}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: valueWeight ?? FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationVal;

  RadarPainter({required this.animationVal});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final ringPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Concentric rings
    canvas.drawCircle(center, maxRadius, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.66, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.33, ringPaint);

    // 2. Crosshairs
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), ringPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), ringPaint);

    // 3. Blip radar sweeping line
    final sweepPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final sweepAngle = animationVal * 2 * pi;
    final sweepEnd = Offset(
      center.dx + maxRadius * cos(sweepAngle),
      center.dy + maxRadius * sin(sweepAngle),
    );
    canvas.drawLine(center, sweepEnd, sweepPaint);

    // Fade sweep trail
    final path = Path()
      ..moveTo(center.dx, center.dy);
    for (int i = 0; i < 30; i++) {
      final angle = sweepAngle - (i * 0.03);
      path.lineTo(
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [Colors.greenAccent.withOpacity(0.15), Colors.transparent],
          [0.9, 1.0],
          TileMode.clamp,
          sweepAngle - 1.0,
          sweepAngle,
        ),
    );

    // 4. Dot approaching center (represents ambulance)
    // Travel progression from outer boundary to center (repeats)
    final progress = (animationVal * 0.25) % 1.0; 
    final currentRadius = maxRadius * (1.0 - progress);
    const dotAngle = 5 * pi / 4; // fixed direction (Top-Left quadrant)
    
    final dotPos = Offset(
      center.dx + currentRadius * cos(dotAngle),
      center.dy + currentRadius * sin(dotAngle),
    );

    // Pulsing ambulance dot
    canvas.drawCircle(
      dotPos,
      5.0,
      Paint()..color = Colors.redAccent..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dotPos,
      10.0 + 3.0 * sin(animationVal * 4 * pi),
      Paint()..color = Colors.redAccent.withOpacity(0.3)..style = PaintingStyle.fill,
    );

    // 5. Patient in the center
    canvas.drawCircle(
      center,
      4.0,
      Paint()..color = Colors.blueAccent..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
