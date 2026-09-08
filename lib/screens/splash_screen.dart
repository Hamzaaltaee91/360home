// Splash Screen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final supabase = SupabaseService();
    final isAuthenticated = supabase.isAuthenticated();

    if (isAuthenticated) {
      try {
        final user = await supabase.getCurrentUser();
        if (mounted) {
          if (user.role == 'buyer') {
            context.go('/buyer-home');
          } else if (user.role == 'realtor') {
            context.go('/realtor-home');
          } else {
            context.go('/login');
          }
        }
      } catch (e) {
        if (mounted) {
          context.go('/login');
        }
      }
    } else {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: const Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'دبّرلي',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'منصة العقارات المعاكسة',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
