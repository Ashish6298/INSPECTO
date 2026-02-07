import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  void _navigateToMain() async {
    // Keep splash for a bit longer to show off the animation
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled Text with cool staggered neon flicker animation
            Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  "INSPECTO".split("").asMap().entries.map((entry) {
                    return Text(
                          entry.value,
                          style: GoogleFonts.syncopate(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            shadows: [
                              const Shadow(
                                blurRadius: 20,
                                color: Color(0xFF6366F1),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: (entry.key * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                        )
                        .then()
                        .animate(
                          onPlay:
                              (controller) => controller.repeat(reverse: true),
                        )
                        .custom(
                          duration: 1.seconds,
                          builder:
                              (context, value, child) => Opacity(
                                opacity: 0.8 + (value * 0.2),
                                child: child,
                              ),
                        );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
                  width: 120,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF818CF8),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                .animate()
                .scaleX(
                  begin: 0,
                  end: 1,
                  duration: 1500.ms,
                  delay: 800.ms,
                  curve: Curves.easeOutExpo,
                )
                .shimmer(
                  delay: 2000.ms,
                  duration: 2000.ms,
                  color: Colors.white38,
                ),
            const SizedBox(height: 48),
            Text(
                  'PROFESSIONAL API TOOLKIT',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                )
                .animate(delay: 1500.ms)
                .fadeIn(duration: 1000.ms)
                .slideY(begin: 1, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
