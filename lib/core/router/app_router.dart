import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/guest/booking_create_screen.dart';
import '../../screens/guest/guest_shell_screen.dart';
import '../../screens/guest/property_detail_screen.dart';
import '../../screens/host/host_shell_screen.dart';
import '../../screens/host/property_create_wizard_screen.dart';
import '../../screens/shared/booking_detail_screen.dart';
import '../../screens/shared/conversations_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  UserModel? _user;
  String _activeRole = 'guest';
  bool _isLoading = true;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(
      authNotifierProvider,
      (previous, next) {
        _isLoading = next.isLoading;
        _user = next.valueOrNull;
        notifyListeners();
      },
      fireImmediately: true,
    );
    _ref.listen<String>(
      activeRoleModeProvider,
      (previous, next) {
        _activeRole = next;
        notifyListeners();
      },
      fireImmediately: true,
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final isAuthRoute = location == '/login' || location == '/register';

    // Still checking initial auth
    if (_isLoading) {
      return null;
    }

    final isAuthenticated = _user != null;

    // If user is already authenticated and visits /login or /register, redirect to app
    if (isAuthenticated && isAuthRoute) {
      return _activeRole == 'host' ? '/host' : '/explore';
    }

    // Root location redirection
    if (location == '/') {
      return (_activeRole == 'host' && isAuthenticated) ? '/host' : '/explore';
    }

    // Booking creation requires login
    if (location.endsWith('/book')) {
      if (!isAuthenticated) return '/login';
    }

    // Host routes require authenticated host user
    if (location.startsWith('/host')) {
      if (!isAuthenticated) return '/login';
      if (!_user!.isHost || _activeRole != 'host') {
        return '/explore';
      }
    }

    // If active role is host and user visits /explore root, route to /host
    if (_activeRole == 'host' && isAuthenticated && location == '/explore') {
      return '/host';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Guest Shell routes
      GoRoute(
        path: '/explore',
        builder: (context, state) => const GuestShellScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const GuestShellScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const GuestShellScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const GuestShellScreen(initialTab: 3),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const GuestShellScreen(initialTab: 4),
      ),

      // Host Shell routes
      GoRoute(
        path: '/host',
        builder: (context, state) => const HostShellScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/host/bookings',
        builder: (context, state) => const HostShellScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/host/notifications',
        builder: (context, state) => const HostShellScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/host/profile',
        builder: (context, state) => const HostShellScreen(initialTab: 3),
      ),
      GoRoute(
        path: '/host/properties/new',
        builder: (context, state) => const PropertyCreateWizardScreen(),
      ),
      GoRoute(
        path: '/host/properties/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PropertyCreateWizardScreen(propertyId: id);
        },
      ),

      // Detail and Action routes
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/properties/:id/book',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BookingCreateScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BookingDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/conversations/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ConversationsScreen(id: id);
        },
      ),
    ],
  );
});
