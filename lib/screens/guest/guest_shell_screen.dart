import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'guest_bookings_screen.dart';

class GuestShellScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const GuestShellScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<GuestShellScreen> createState() => _GuestShellScreenState();
}

class _GuestShellScreenState extends ConsumerState<GuestShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    ExploreScreen(),
    GuestBookingsScreen(),
    FavoritesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final tr = context.tr;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            selectedIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
            label: tr.navExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
            label: tr.navBookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded, color: AppTheme.secondary),
            label: tr.navFavorites,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_rounded, color: AppTheme.primary),
            ),
            label: tr.navInbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
            label: tr.navProfile,
          ),
        ],
      ),
    );
  }
}

