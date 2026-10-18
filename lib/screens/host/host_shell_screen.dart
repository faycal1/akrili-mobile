import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'host_bookings_screen.dart';
import 'host_properties_screen.dart';

class HostShellScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HostShellScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HostShellScreen> createState() => _HostShellScreenState();
}

class _HostShellScreenState extends ConsumerState<HostShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HostPropertiesScreen(),
    HostBookingsScreen(),
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
          const NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded, color: AppTheme.primary),
            label: 'Listings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
            label: 'Reservations',
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
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            label: 'Host Profile',
          ),
        ],
      ),
    );
  }
}
