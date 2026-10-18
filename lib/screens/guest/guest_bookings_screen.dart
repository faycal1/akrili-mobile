import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../shared/widgets/akrili_image.dart';

class GuestBookingsScreen extends ConsumerStatefulWidget {
  const GuestBookingsScreen({super.key});

  @override
  ConsumerState<GuestBookingsScreen> createState() => _GuestBookingsScreenState();
}

class _GuestBookingsScreenState extends ConsumerState<GuestBookingsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authUser = ref.watch(authNotifierProvider).valueOrNull;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.myBookingsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_outlined, size: 36, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(tr.signInToViewBookings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  tr.bookingsSignInPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(tr.signIn),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(tr.createAccount),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingsAsync = ref.watch(guestBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.myBookingsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(tr.seeAll, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(tr.statusPending, 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip(tr.statusConfirmed, 'confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip(tr.statusRejected, 'rejected'),
                const SizedBox(width: 8),
                _buildFilterChip(tr.statusCompleted, 'completed'),
              ],
            ),
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.secondary),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger les réservations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(guestBookingsProvider),
                  child: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
        data: (bookings) {
          final filtered = bookings.where((b) {
            if (_selectedFilter == 'all') return true;
            return b.status.toLowerCase() == _selectedFilter;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilter == 'all'
                          ? 'Aucune réservation pour le moment'
                          : 'Aucune réservation dans cette catégorie',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lorsque vous réservez des séjours en Algérie, ils apparaîtront ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(guestBookingsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = filtered[index];
                return _BookingCard(booking: booking);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981); // Emerald
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'rejected':
      case 'cancelled':
        return AppTheme.secondary;
      case 'completed':
        return const Color(0xFF6B7280); // Gray
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLocalized(String status, AppLocalizations tr) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return tr.statusConfirmed;
      case 'pending':
        return tr.statusPending;
      case 'rejected':
        return tr.statusRejected;
      case 'cancelled':
        return tr.statusCancelled;
      case 'completed':
        return tr.statusCompleted;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final statusColor = _statusColor(booking.status);
    final property = booking.property;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/bookings/${booking.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Reference & Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Réf : ${booking.reference.isNotEmpty ? booking.reference : "#${booking.id}"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(booking.status), size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusLocalized(booking.status, tr).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property details row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AkriliImage(
                    imageUrl: property?.coverUrl,
                    width: 70,
                    height: 70,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property?.title ?? 'Séjour Akrili',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (property?.commune != null || property?.wilaya != null)
                          Text(
                            '${property?.commune?.name ?? ""}, ${property?.wilaya?.name ?? ""}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.checkIn} → ${booking.checkOut}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer: Total & Guests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${booking.guests} ${tr.guestsUnit}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${NumberFormat("#,###").format(booking.totalPrice)} DZD',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
