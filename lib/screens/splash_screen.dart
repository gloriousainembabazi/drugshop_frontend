import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Even faster animation
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.forward();
    
    // REMOVED: _precacheLogo() from here
    
    _navigateToNext();
  }
  
  // ADDED: Move precaching to didChangeDependencies
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheLogo();
  }
  
  Future<void> _precacheLogo() async {
    await precacheImage(const AssetImage('assets/images/logo.jpg'), context);
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(AppDurations.splashDuration);
    
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool(StorageKeys.firstLaunch) ?? true;
    final String? token = prefs.getString(StorageKeys.token);
    
    if (isFirstLaunch) {
      await prefs.setBool(StorageKeys.firstLaunch, false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } else if (token != null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pharmacy Logo - Optimized for fast loading
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGreen,
                    borderRadius: BorderRadius.circular(80),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                      cacheWidth: 160, // Reduced to actual display size
                      cacheHeight: 160, // Reduced to actual display size
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gradient logo
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy,
                            color: Colors.white,
                            size: 80,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24), // Reduced spacing
                
              
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'HIS GRACE',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'DRUGSHOP',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
               
                
                Text(
                  AppStrings.tagline,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.darkGrey,
                    letterSpacing: 0.3,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  strokeWidth: 2.5,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  AppStrings.loading,
                  style: GoogleFonts.poppins(
                    color: AppColors.darkGrey,
                    fontSize: 12,
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