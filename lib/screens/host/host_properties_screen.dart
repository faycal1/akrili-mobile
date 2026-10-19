import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../providers/property_provider.dart';
import '../shared/widgets/akrili_image.dart';

class HostPropertiesScreen extends ConsumerWidget {
  const HostPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final propertiesAsync = ref.watch(hostPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            Text(tr.navListings),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: tr.retry,
            onPressed: () => ref.refresh(hostPropertiesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/properties/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(tr.listYourProperty),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: propertiesAsync.when(
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
                  'Impossible de charger les biens',
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
                  onPressed: () => ref.refresh(hostPropertiesProvider),
                  child: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
        data: (properties) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final activeCount = properties.where((p) => p.status == 'published' || p.status == 'active').length;

          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_business_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aucune annonce pour le moment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos hébergements en location courte durée apparaîtront ici. Gérez vos réservations et tarifs en temps réel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/host/properties/new'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(tr.listYourProperty),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(hostPropertiesProvider);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Host Portfolio Stats Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withOpacity(0.12),
                        const Color(0xFF6366F1).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Total annonces',
                        value: '${properties.length}',
                        icon: Icons.holiday_village_rounded,
                        color: AppTheme.primary,
                      ),
                      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.25)),
                      _StatColumn(
                        label: 'Logements actifs',
                        value: '$activeCount',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Property list items
                ...properties.map(
                  (property) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HostPropertyCard(property: property),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
}

class _HostPropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _HostPropertyCard({required this.property});

  bool get _isEditable =>
      property.status.toLowerCase() == 'draft' ||
      property.status.toLowerCase() == 'rejected';

  /// Confirms, then deletes the listing server-side and refreshes the list.
  /// Always returns false so the card is removed by the provider refresh
  /// rather than by the Dismissible itself (keeps the list as source of truth).
  Future<bool> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations tr,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.deleteListing),
        content: Text(tr.deleteListingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return false;
    }
    try {
      await ref.read(propertyRepositoryProvider).deleteHostProperty(property.id);
      ref.invalidate(hostPropertiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.listingDeleted)),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        final msg = e.response?.statusCode == 422
            ? tr.cannotDeleteListing
            : tr.serverErrorMsg;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.serverErrorMsg)),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    String statusLabel;
    switch (property.status.toLowerCase()) {
      case 'published':
      case 'active':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'ACTIF';
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'EN ATTENTE';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'REFUSÉ';
        break;
      case 'draft':
      default:
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'BROUILLON';
        break;
    }

    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Draft/rejected listings open the editor (the only statuses the
            // backend allows editing); others open the public detail view.
            final editable = property.status.toLowerCase() == 'draft' ||
                property.status.toLowerCase() == 'rejected';
            if (editable) {
              context.push('/host/properties/${property.id}/edit');
              return;
            }
            context.push('/properties/${property.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover thumbnail
                AkriliImage(
                  imageUrl: property.coverUrl,
                  width: 96,
                  height: 96,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 14),

                // Property details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (property.instantBooking)
                            Row(
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 13, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  tr.instantBookingBadge,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.primary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algérie"}',
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${property.capacity} ${tr.guestsUnit} • ${property.bedrooms} ch.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textSecondaryLight),
                          ),
                          Text(
                            '${NumberFormat("#,###").format(property.nightlyPrice)} DZD',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pin the swipe gestures to physical direction regardless of locale:
    // Dismissible resolves startToEnd/endToStart against text direction, which
    // flips them under RTL. Forcing LTR here keeps right-swipe = edit and
    // left-swipe = delete everywhere, while the card itself is restored to the
    // ambient direction so Arabic content still lays out RTL.
    final ambientDirection = Directionality.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dismissible(
        key: ValueKey('host-property-${property.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right: edit. Only draft/rejected listings are editable.
            if (_isEditable) {
              context.push('/host/properties/${property.id}/edit');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr.onlyDraftEditable)),
              );
            }
            return false;
          }
          // Swipe left: delete with confirmation.
          return _confirmAndDelete(context, ref, tr);
        },
        background: _buildSwipeBackground(
          color: _isEditable ? AppTheme.primary : Colors.grey,
          icon: _isEditable ? Icons.edit_rounded : Icons.lock_outline_rounded,
          label: tr.edit,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: const Color(0xFFEF4444),
          icon: Icons.delete_rounded,
          label: tr.delete,
          alignment: Alignment.centerRight,
        ),
        child: Directionality(
          textDirection: ambientDirection,
          child: card,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]
            : [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white),
              ],
      ),
    );
  }
}

