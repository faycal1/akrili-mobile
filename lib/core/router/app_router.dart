import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/guest/booking_create_screen.dart';
import '../../screens/guest/guest_shell_screen.dart';
import '../../screens/guest/property_detail_screen.dart';
import '../../screens/host/host_shell_screen.dart';
import '../../screens/shared/booking_detail_screen.dart';
import '../../screens/shared/conversations_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
    _ref.listen(activeRoleModeProvider, (_, __) => notifyListeners());
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
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final activeRole = ref.read(activeRoleModeProvider);

      final isLoggingIn = state.matchedLocation == '/login';

      // Still checking initial auth
      if (authState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;
      final isAuthenticated = user != null;

      // Unauthenticated users must go to login
      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // If user is already authenticated and visits /login, redirect
      if (isLoggingIn) {
        return activeRole == 'host' ? '/host' : '/explore';
      }

      // Root location redirection
      if (state.matchedLocation == '/') {
        return activeRole == 'host' ? '/host' : '/explore';
      }

      // Block non-hosts or guest-mode users from accessing /host routes
      if (state.matchedLocation.startsWith('/host')) {
        if (!user.isHost || activeRole != 'host') {
          return '/explore';
        }
      }

      // If active role is host and user visits /explore root, route to /host
      if (activeRole == 'host' && state.matchedLocation == '/explore') {
        return '/host';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
