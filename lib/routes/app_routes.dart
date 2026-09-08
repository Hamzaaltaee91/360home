// App Routes Navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/buyer/buyer_home_screen.dart';
import '../screens/buyer/create_request_screen.dart';
import '../screens/buyer/browse_offers_screen.dart';
import '../screens/buyer/offer_details_screen.dart';
import '../screens/realtor/realtor_home_screen.dart';
import '../screens/realtor/browse_requests_screen.dart';
import '../screens/realtor/create_offer_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';

final appRoutes = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash & Auth
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Buyer Routes
    GoRoute(
      path: '/buyer-home',
      builder: (context, state) => const BuyerHomeScreen(),
    ),
    GoRoute(
      path: '/create-request',
      builder: (context, state) => const CreateRequestScreen(),
    ),
    GoRoute(
      path: '/browse-offers',
      builder: (context, state) => const BrowseOffersScreen(),
    ),
    GoRoute(
      path: '/offer/:offerId',
      builder: (context, state) {
        final offerId = state.pathParameters['offerId']!;
        return OfferDetailsScreen(offerId: offerId);
      },
    ),

    // Realtor Routes
    GoRoute(
      path: '/realtor-home',
      builder: (context, state) => const RealtorHomeScreen(),
    ),
    GoRoute(
      path: '/browse-requests',
      builder: (context, state) => const BrowseRequestsScreen(),
    ),
    GoRoute(
      path: '/create-offer/:requestId',
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return CreateOfferScreen(requestId: requestId);
      },
    ),

    // Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('خطأ')),
    body: Center(
      child: Text('الصفحة غير موجودة: ${state.location}'),
    ),
  ),
);
