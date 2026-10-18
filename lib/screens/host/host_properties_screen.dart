import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_business_rounded,
                        size: 52,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucune annonce publiée pour le moment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vos annonces de location courte durée apparaîtront ici une fois créées sur la plateforme Akrili.',
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
              return ref.refresh(hostPropertiesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final property = properties[index];
                return _HostPropertyCard(property: property);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HostPropertyCard extends StatelessWidget {
  final PropertyModel property;
  const _HostPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isPublished = property.status == 'published' || property.status == 'active';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/properties/${property.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail
              AkriliImage(
                imageUrl: property.coverUrl,
                width: 90,
                height: 90,
                borderRadius: BorderRadius.circular(10),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPublished ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPublished ? 'ACTIF' : property.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPublished ? const Color(0xFF10B981) : Colors.grey,
                            ),
                          ),
                        ),
                        if (property.instantBooking)
                          Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 12, color: Colors.amber),
                              Text(tr.instantBookingBadge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? ""}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${property.capacity} ${tr.guestsUnit} • ${property.bedrooms} ${tr.bedroomsUnit}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                        ),
                        Text(
                          '${NumberFormat("#,###").format(property.nightlyPrice)} DZD',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
