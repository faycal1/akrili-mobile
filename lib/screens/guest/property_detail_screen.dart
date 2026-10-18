import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../providers/auth_provider.dart';
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
              Container(
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
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF0FDFA),
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
