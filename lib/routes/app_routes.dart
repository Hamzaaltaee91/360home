// App Routes Navigation

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/buyer/buyer_home_screen.dart';
import '../screens/buyer/create_request_screen.dart';
import '../screens/buyer/browse_offers_screen.dart';
import '../screens/buyer/offer_details_screen.dart';
import '../screens/buyer/request_details_screen.dart';
import '../screens/realtor/realtor_home_screen.dart';
import '../screens/realtor/browse_requests_screen.dart';
import '../screens/realtor/create_offer_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/not_found_screen.dart';

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
  static const String forgotPassword = '/forgot-password';

  // Buyer
  static const String buyer = '/buyer';
  static const String buyerHome = '/buyer-home';
  static const String createRequest = '/create-request';
  static const String browseOffers = '/browse-offers';
  static const String offerDetails = '/offer/:offerId';
  static const String requestDetails = '/request/:requestId';

  // Realtor
  static const String realtor = '/realtor';
  static const String realtorHome = '/realtor-home';
  static const String browseRequests = '/browse-requests';
  static const String createOffer = '/create-offer/:requestId';

  // Profile
  static const String profile = '/profile';

  // Admin
  static const String adminDashboard = '/admin';

  /// Builds the concrete path for an offer details route.
  static String offerDetailsPath(String offerId) => '/offer/$offerId';

  /// Builds the concrete path for a request details route.
  static String requestDetailsPath(String requestId) => '/request/$requestId';

  /// Builds the concrete path for a create-offer route.
  static String createOfferPath(String requestId) => '/create-offer/$requestId';

  /// Resolves an incoming deep link (full URL or path) to a valid in-app
  /// location. Returns `null` when the link cannot be resolved, letting the
  /// caller fall back to the role home.
  static String? resolveDeepLink(String? link) {
    if (link == null || link.isEmpty) return null;

    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    // Use the path portion so absolute URLs (https://host/offer/123) and
    // relative paths (/offer/123) resolve identically.
    final path = uri.path.isEmpty ? link : uri.path;
    if (path.isEmpty || path == '/') return null;

    // Only allow known, parameterized deep-link targets.
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length != 2) return null;

    final id = segments[1];
    switch (segments[0]) {
      case 'offer':
        return offerDetailsPath(id);
      case 'request':
        return requestDetailsPath(id);
      case 'create-offer':
        return createOfferPath(id);
      default:
        return null;
    }
  }

  /// Routes reachable without an authenticated session.
  static const Set<String> publicRoutes = {
    splash,
    login,
    signup,
    forgotPassword,
  };

  /// Returns the home route for a given user role.
  static String homeForRole(String? role) {
    switch (role) {
      case 'realtor':
        return realtorHome;
      case 'admin':
        return adminDashboard;
      case 'buyer':
      default:
        return buyerHome;
    }
  }
}

/// Bridges a [Stream] to a [Listenable] so [GoRouter] can re-run its
/// `redirect` whenever the auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRoutes = GoRouter(
  initialLocation: RouteNames.splash,
  refreshListenable:
      GoRouterRefreshStream(SupabaseService().authStateChanges),
  redirect: (context, state) {
    final service = SupabaseService();
    final isAuthenticated = service.isAuthenticated();
    final location = state.matchedLocation;
    final isPublicRoute = RouteNames.publicRoutes.contains(location);

    // Unauthenticated users may only access public routes.
    if (!isAuthenticated) {
      return isPublicRoute ? null : RouteNames.login;
    }

    // Resolve deep links to a canonical in-app location.
    final deepLink = RouteNames.resolveDeepLink(state.uri.toString());
    if (deepLink != null && deepLink != location) {
      return deepLink;
    }

    // Authenticated users should not linger on auth/splash screens.
    if (isPublicRoute) {
      return RouteNames.homeForRole(service.currentUserRole);
    }

    // Role-based access control.
    final role = service.currentUserRole;
    final isBuyerRoute = location.startsWith('/buyer') ||
        location == RouteNames.createRequest ||
        location == RouteNames.browseOffers ||
        location.startsWith('/offer/') ||
        location.startsWith('/request/');
    final isRealtorRoute = location.startsWith('/realtor') ||
        location == RouteNames.browseRequests ||
        location.startsWith('/create-offer/');
    final isAdminRoute = location.startsWith('/admin');

    if (isBuyerRoute && role != 'buyer') {
      return RouteNames.homeForRole(role);
    }
    if (isRealtorRoute && role != 'realtor') {
      return RouteNames.homeForRole(role);
    }
    if (isAdminRoute && role != 'admin') {
      return RouteNames.homeForRole(role);
    }

    return null;
  },
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
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
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
    GoRoute(
      path: RouteNames.requestDetails,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return RequestDetailsScreen(requestId: requestId);
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
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.location),
);
