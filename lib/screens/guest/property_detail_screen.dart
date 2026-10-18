import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/property_provider.dart';
import '../shared/widgets/akrili_image.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyDetailProvider(propertyId));

    return Scaffold(
      body: propertyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading property: $err'),
              ElevatedButton(
                onPressed: () => ref.invalidate(propertyDetailProvider(propertyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (property) => _DetailContent(property: property),
      ),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final PropertyModel property;
  const _DetailContent({required this.property});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images = [
      if (property.coverUrl != null) property.coverUrl!,
      ...property.gallery,
    ];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App Bar with Image Carousel
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(
                      property.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: property.isFavorite ? AppTheme.secondary : Colors.black87,
                    ),
                    onPressed: () async {
                      final repo = ref.read(favoriteRepositoryProvider);
                      await repo.toggleFavorite(property.id);
                      ref.invalidate(propertyDetailProvider(property.id));
                      ref.invalidate(propertiesListProvider);
                      ref.invalidate(favoritesListProvider);
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: images.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _currentImageIndex = i),
                            itemBuilder: (ctx, idx) => AkriliImage(
                              imageUrl: images[idx],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1}/${images.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.home_work_outlined, size: 64),
                      ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algeria"}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const Spacer(),
                        if (property.averageRating != null) ...[
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            property.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            ' (${property.reviewsCount})',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Specs row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SpecItem(icon: Icons.people_outline, label: '${property.capacity} guests'),
                        _SpecItem(icon: Icons.bedroom_parent_outlined, label: '${property.bedrooms} bedrooms'),
                        _SpecItem(icon: Icons.bathtub_outlined, label: '${property.bathrooms} baths'),
                        _SpecItem(icon: Icons.home_outlined, label: property.type),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Host Info
                    if (property.owner != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.15),
                            radius: 24,
                            child: Text(
                              property.owner!.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hosted by ${property.owner!.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (property.owner!.isVerified)
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: AppTheme.primary, size: 14),
                                    SizedBox(width: 4),
                                    Text('Verified Host', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    if (property.description != null && property.description!.isNotEmpty) ...[
                      const Text(
                        'About this space',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.description!,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Amenities
                    if (property.amenities.isNotEmpty) ...[
                      const Text(
                        'What this place offers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: property.amenities.map((a) {
                          return Chip(
                            avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primary),
                            label: Text(a.name),
                            backgroundColor: AppTheme.primary.withOpacity(0.06),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Pricing breakdown summary
                    const Text(
                      'Pricing Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _PriceRow(label: 'Nightly Rate', amount: '${property.nightlyPrice} DZD'),
                    if (property.cleaningFee > 0)
                      _PriceRow(label: 'Cleaning Fee', amount: '${property.cleaningFee} DZD'),
                    if (property.deposit > 0)
                      _PriceRow(label: 'Security Deposit', amount: '${property.deposit} DZD'),
                    _PriceRow(label: 'Minimum Stay', amount: '${property.minNights} night(s)'),

                    const SizedBox(height: 100), // bottom padding for CTA bar
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky Bottom CTA Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${property.nightlyPrice} DZD',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Text(
                        'per night',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 48),
                    ),
                    onPressed: () {
                      context.push('/properties/${property.id}/book');
                    },
                    child: Text(property.instantBooking ? 'Instant Book' : 'Reserve Stay'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.primary),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
