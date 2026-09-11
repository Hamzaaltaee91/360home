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

/// Centralized route path constants.
///
/// Use these instead of raw string literals so that route definitions,
/// navigation calls, and deep links stay in sync.
class RouteNames {
  const RouteNames._();

  // Splash & Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';

  // Buyer
  static const String buyer = '/buyer';
  static const String buyerHome = '/buyer-home';
  static const String createRequest = '/create-request';
  static const String browseOffers = '/browse-offers';
  static const String offerDetails = '/offer/:offerId';

  // Realtor
  static const String realtor = '/realtor';
  static const String realtorHome = '/realtor-home';
  static const String browseRequests = '/browse-requests';
  static const String createOffer = '/create-offer/:requestId';

  // Profile
  static const String profile = '/profile';

  /// Builds the concrete path for an offer details route.
  static String offerDetailsPath(String offerId) => '/offer/$offerId';

  /// Builds the concrete path for a create-offer route.
  static String createOfferPath(String requestId) => '/create-offer/$requestId';
}

final appRoutes = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    // Splash & Auth
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.signup,
      builder: (context, state) => const SignupScreen(),
    ),

    // Buyer Routes
    GoRoute(
      path: RouteNames.buyer,
      builder: (context, state) => const BuyerHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.buyerHome,
      builder: (context, state) => const BuyerHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.createRequest,
      builder: (context, state) => const CreateRequestScreen(),
    ),
    GoRoute(
      path: RouteNames.browseOffers,
      builder: (context, state) => const BrowseOffersScreen(),
    ),
    GoRoute(
      path: RouteNames.offerDetails,
      builder: (context, state) {
        final offerId = state.pathParameters['offerId']!;
        return OfferDetailsScreen(offerId: offerId);
      },
    ),

    // Realtor Routes
    GoRoute(
      path: RouteNames.realtor,
      builder: (context, state) => const RealtorHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.realtorHome,
      builder: (context, state) => const RealtorHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.browseRequests,
      builder: (context, state) => const BrowseRequestsScreen(),
    ),
    GoRoute(
      path: RouteNames.createOffer,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return CreateOfferScreen(requestId: requestId);
      },
    ),

    // Profile
    GoRoute(
      path: RouteNames.profile,
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
