import 'dart:async';
import 'package:flutter/material.dart';
import '../models/health_advisory.dart';
import 'glass_card.dart';

class HealthAdvisoryCarousel extends StatefulWidget {
  final List<HealthAdvisory> advisories;

  const HealthAdvisoryCarousel({Key? key, required this.advisories}) : super(key: key);

  @override
  State<HealthAdvisoryCarousel> createState() => _HealthAdvisoryCarouselState();
}

class _HealthAdvisoryCarouselState extends State<HealthAdvisoryCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.advisories.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % widget.advisories.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity, BuildContext context) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orangeAccent;
      case 'info':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.gpp_bad;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.advisories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.advisories.length,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final advisory = widget.advisories[index];
          final color = _getSeverityColor(advisory.severity, context);
          final icon = _getSeverityIcon(advisory.severity);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              color: color,
              opacity: 0.05,
              blur: 15,
              border: Border.all(color: color.withOpacity(0.35), width: 1.5),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          advisory.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advisory.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
