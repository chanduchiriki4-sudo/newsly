import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  late Animation<Offset> nOffset;
  late Animation<Offset> eOffset;
  late Animation<Offset> wOffset;
  late Animation<Offset> sOffset;

  late Animation<double> lettersOpacity;
  late Animation<double> compassOpacity;
  late Animation<double> compassRotation;
  late Animation<double> lySuffixOpacity;
  late Animation<double> taglineOpacity;
  late Animation<double> finalScale;
  late Animation<double> finalFade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 4200),
      vsync: this,
    );

    compassOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    compassRotation = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    lettersOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.15, 0.45, curve: Curves.easeIn),
    );

    nOffset = Tween<Offset>(begin: const Offset(0, -3), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)),
    );
    eOffset = Tween<Offset>(begin: const Offset(3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic)),
    );
    wOffset = Tween<Offset>(begin: const Offset(-3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic)),
    );
    sOffset = Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic)),
    );

    lySuffixOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.62, 0.8, curve: Curves.easeIn),
    );

    taglineOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.75, 0.9, curve: Curves.easeIn),
    );

    finalScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.15, 0.7, curve: Curves.easeOut)),
    );

    finalFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
    );

    controller.forward();

    Timer(const Duration(milliseconds: 4300), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _letter(String text, {double size = 46}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        height: 1,
      ),
    );
  }

  Widget _tick(double angleDegrees, double radius) {
    final radians = angleDegrees * math.pi / 180;
    final dx = radius * math.cos(radians);
    final dy = radius * math.sin(radians);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFE64A19)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Opacity(
                opacity: 1.0 - finalFade.value,
                child: Transform.scale(scale: finalScale.value, child: child),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: compassOpacity,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: compassOpacity,
                        child: AnimatedBuilder(
                          animation: compassRotation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: compassRotation.value,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      FadeTransition(
                        opacity: compassOpacity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _tick(-90, 110),
                            _tick(0, 110),
                            _tick(90, 110),
                            _tick(180, 110),
                            _tick(-45, 110),
                            _tick(45, 110),
                            _tick(135, 110),
                            _tick(-135, 110),
                          ],
                        ),
                      ),
                      FadeTransition(
                        opacity: lettersOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SlideTransition(position: nOffset, child: _letter('N')),
                            SlideTransition(position: eOffset, child: _letter('E')),
                            SlideTransition(position: wOffset, child: _letter('W')),
                            SlideTransition(position: sOffset, child: _letter('S')),
                            FadeTransition(
                              opacity: lySuffixOpacity,
                              child: Text(
                                'ly',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: taglineOpacity,
                  child: const Text(
                    'NORTH  •  EAST  •  WEST  •  SOUTH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: taglineOpacity,
                  child: const Text(
                    'Stay Informed, Stay Ahead',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}