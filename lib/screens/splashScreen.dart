import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Container(
                          height: 270,
                          width: 270,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ), // Background color
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Optional: rounded corners
                          ),
                          padding: EdgeInsets.all(
                            2,
                          ), // Optional: space inside the container
                          child: Image.asset(
                            'assets/images/BusSync_Logo.png',
                            height: 300,
                            width: 300,
                          ),
                        ),
                      ),
                      // App Tagline

                      // Loading Indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromARGB(
                              255,
                              0,
                              53,
                              70,
                            ).withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
