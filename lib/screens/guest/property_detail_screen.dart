import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_error_helper.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../data/models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/property_provider.dart';
import '../shared/widgets/akrili_image.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final propertyAsync = ref.watch(propertyDetailProvider(propertyId));

    return propertyAsync.when(
      loading: () => const _PropertyDetailSkeleton(),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger ce séjour : $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => ref.invalidate(propertyDetailProvider(propertyId)),
                  label: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (property) => _DetailContent(property: property),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final PropertyModel property;
  const _DetailContent({required this.property});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onToggleFavorite() async {
    HapticFeedback.mediumImpact();
    _heartAnimController.forward(from: 0.0);

    final authUser = ref.read(authNotifierProvider).valueOrNull;
    if (authUser == null) {
      context.push('/login');
      return;
    }

    final repo = ref.read(favoriteRepositoryProvider);
    await repo.toggleFavorite(widget.property.id);
    ref.invalidate(propertyDetailProvider(widget.property.id));
    ref.invalidate(propertiesListProvider);
    ref.invalidate(favoritesListProvider);
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('clim') || lower.contains('air') || lower.contains('ac')) return Icons.ac_unit_rounded;
    if (lower.contains('piscine') || lower.contains('pool')) return Icons.pool_rounded;
    if (lower.contains('parking') || lower.contains('garage')) return Icons.local_parking_rounded;
    if (lower.contains('cuisine') || lower.contains('kitchen')) return Icons.kitchen_rounded;
    if (lower.contains('tv') || lower.contains('télé')) return Icons.tv_rounded;
    if (lower.contains('mer') || lower.contains('plage') || lower.contains('sea')) return Icons.waves_rounded;
    if (lower.contains('chauffage') || lower.contains('heat')) return Icons.thermostat_rounded;
    if (lower.contains('lave') || lower.contains('washer')) return Icons.local_laundry_service_rounded;
    if (lower.contains('balcon') || lower.contains('terrasse')) return Icons.deck_rounded;
    if (lower.contains('jardin') || lower.contains('garden')) return Icons.park_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final property = widget.property;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final images = [
      if (property.coverUrl != null && property.coverUrl!.isNotEmpty) property.coverUrl!,
      ...property.gallery,
    ];

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${property.nightlyPrice} DZD',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'par nuit • sans frais cachés',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Builder(
                builder: (context) {
                  final currentUser = ref.watch(authNotifierProvider).valueOrNull;
                  final isOwner = currentUser != null && property.owner != null && currentUser.id == property.owner!.id;

                  if (isOwner) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr.cannotBookOwnProperty)),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_outlined, color: isDark ? Colors.white70 : Colors.black87, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Votre annonce',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.primaryButtonShadow,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push('/properties/${property.id}/book');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (property.instantBooking) ...[
                            const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            property.instantBooking
                                ? 'Réservation instantanée'
                                : 'Réserver ce séjour',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Image Carousel & Frosted Glass Action Buttons
            SliverAppBar(
              expandedHeight: 330,
              pinned: true,
              elevation: 0,
              stretch: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.92),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                ScaleTransition(
                  scale: _heartScaleAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.92),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        property.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: property.isFavorite ? AppTheme.secondary : Colors.black87,
                        size: 20,
                      ),
                      onPressed: _onToggleFavorite,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                              height: 330,
                              width: double.infinity,
                            ),
                          ),
                          // Top & Bottom gradients for readability
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 90,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 70,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: AppTheme.imageVignetteGradient,
                              ),
                            ),
                          ),
                          // Modern Image Counter Pill
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_currentImageIndex + 1} / ${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.apartment_rounded, size: 64, color: Colors.grey),
                        ),
                      ),
              ),
            ),

            // Main Content Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: Instant Booking or Verified Stay
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Logement certifié Akrili',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (property.instantBooking) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  tr.instantBookingBadge,
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location & Rating Row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algérie"}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (property.averageRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  property.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Specs Grid: 4 modern mini-cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            Icons.group_outlined,
                            '${property.capacity}',
                            tr.guestsUnit,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            Icons.bed_outlined,
                            '${property.bedrooms}',
                            tr.bedroomsUnit,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            Icons.bathtub_outlined,
                            '${property.bathrooms}',
                            tr.bathroomsUnit,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            Icons.home_work_outlined,
                            property.type,
                            'Type',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Host Profile Card
                    if (property.owner != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary, width: 2),
                              ),
                              child: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.15),
                                radius: 26,
                                child: Text(
                                  property.owner!.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hôte : ${property.owner!.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppTheme.primary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hôte vérifié sur Akrili',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 24),
                    ],

                    // Description Section
                    if (property.description != null && property.description!.isNotEmpty) ...[
                      const Text(
                        'À propos de ce logement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        property.description!,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Amenities Section
                    if (property.amenities.isNotEmpty) ...[
                      const Text(
                        'Équipements inclus',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: property.amenities.map((a) {
                          final icon = _getAmenityIcon(a.name);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : AppTheme.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 17, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Pricing breakdown card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr.priceSummary,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 22),
                          _priceRow(tr.nightlyPriceRow, '${property.nightlyPrice} DZD', isDark),
                          if (property.cleaningFee > 0)
                            _priceRow(tr.cleaningFeeRow, '${property.cleaningFee} DZD', isDark),
                          if (property.deposit > 0)
                            _priceRow(tr.depositRow, '${property.deposit} DZD', isDark),
                          _priceRow(
                            tr.minNightsLabel,
                            '${property.minNights} ${tr.nightsUnit}',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Airbnb REVIEWS & RATINGS SECTION
                    _buildReviewsSection(context, ref, property),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSpecCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13.5,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
  ) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuestFavorite =
        (property.averageRating ?? 0) >= 4.8 && property.reviewsCount >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guest Favorite Badge (Airbnb signature)
        if (isGuestFavorite) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF3B2506), const Color(0xFF1E293B)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.amber.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.guestFavoriteBadge,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr.guestFavoriteSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Eligible Stay Review CTA Banner (Airbnb prompt to rate stay)
        if (property.eligibleBooking != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.primary.withOpacity(0.18), const Color(0xFF1E293B)]
                    : [AppTheme.primaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr.eligibleStayBannerTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tr.eligibleStayBannerSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                if (property.eligibleBooking!.checkIn != null &&
                    property.eligibleBooking!.checkOut != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${property.eligibleBooking!.checkIn} → ${property.eligibleBooking!.checkOut} (${property.eligibleBooking!.reference})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary.withOpacity(0.85),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _showLeaveReviewModal(
                    context,
                    property.eligibleBooking!.id,
                    property.id,
                  ),
                  icon: const Icon(Icons.rate_review_rounded, size: 18),
                  label: Text(tr.writeReviewBtn),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        // Section Title & Overall Rating Header
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
            const SizedBox(width: 8),
            Text(
              property.averageRating != null
                  ? '${property.averageRating!.toStringAsFixed(1)} · ${tr.reviewsCountText(property.reviewsCount)}'
                  : tr.reviewsTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rating Breakdown Bar Chart (Airbnb 5-1 star distribution)
        if (property.reviewsCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.ratingBreakdown,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                ...List.generate(5, (idx) {
                  final star = 5 - idx;
                  final count = property.ratingDistribution[star] ?? 0;
                  final ratio = property.reviewsCount > 0
                      ? (count / property.reviewsCount)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$star',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.06),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Reviews List
        if (property.reviews.isNotEmpty) ...[
          ...property.reviews.take(3).map((review) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReviewCard(review, isDark, tr),
            );
          }),
          if (property.reviews.length > 3) ...[
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => _showAllReviewsModal(context, property),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color:
                      isDark ? Colors.white24 : Colors.black.withOpacity(0.15),
                ),
              ),
              child: Center(
                child: Text(
                  tr.seeAllReviews(property.reviewsCount),
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ] else ...[
          // Empty state for reviews
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 40,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr.noReviewsYet,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.beFirstToReview,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review, bool isDark, AppLocalizations tr) {
    final initial = review.userName.isNotEmpty
        ? review.userName.substring(0, 1).toUpperCase()
        : 'V';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (review.createdAtFormatted != null)
                      Text(
                        review.createdAtFormatted!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? Colors.grey[200] : Colors.black87,
            ),
          ),
          if (review.reply != null && review.reply!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primary.withOpacity(0.08)
                    : AppTheme.primaryLight.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        tr.hostReplyTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.reply!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviewsModal(BuildContext context, PropertyModel property) {
    HapticFeedback.lightImpact();
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (sheetCtx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${property.averageRating != null ? property.averageRating!.toStringAsFixed(1) : ''} · ${tr.reviewsCountText(property.reviewsCount)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: property.reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (c, idx) {
                      return _buildReviewCard(
                          property.reviews[idx], isDark, tr);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLeaveReviewModal(
    BuildContext context,
    int bookingId,
    int propertyId,
  ) {
    HapticFeedback.lightImpact();
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            String getRatingLabel(int r) {
              switch (r) {
                case 5:
                  return tr.ratingLabel5;
                case 4:
                  return tr.ratingLabel4;
                case 3:
                  return tr.ratingLabel3;
                case 2:
                  return tr.ratingLabel2;
                case 1:
                default:
                  return tr.ratingLabel1;
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr.reviewModalTitle,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.reviewModalSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Large Airbnb-style interactive stars
                    Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.amber.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starNum = index + 1;
                              final isSelected = starNum <= rating;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    rating = starNum;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Icon(
                                    isSelected
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              getRatingLabel(rating),
                              key: ValueKey(rating),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: tr.commentPlaceholder,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 1000,
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setModalState(() => errorMessage = null);
                        }
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.secondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final comment = commentController.text.trim();
                              if (comment.length < 5) {
                                setModalState(() {
                                  errorMessage = tr.reviewMinChars;
                                });
                                return;
                              }
                              setModalState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });
                              try {
                                HapticFeedback.mediumImpact();
                                final repo =
                                    ref.read(bookingRepositoryProvider);
                                await repo.submitReview(
                                  bookingId: bookingId,
                                  rating: rating,
                                  comment: comment,
                                );
                                ref.invalidate(
                                    propertyDetailProvider(propertyId));
                                ref.invalidate(guestBookingsProvider);
                                ref.invalidate(
                                    bookingDetailProvider(bookingId));
                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr.reviewSubmittedSuccess),
                                      backgroundColor: AppTheme.emerald,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  errorMessage = ApiErrorHelper.parse(e, tr);
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr.publishReviewBtn,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PropertyDetailSkeleton extends StatelessWidget {
  const _PropertyDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white70,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: Container(
              color: baseColor.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 220,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Container(
                          height: 70,
                          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
