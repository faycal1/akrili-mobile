import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../shared/widgets/akrili_image.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final authUser = ref.watch(authNotifierProvider).valueOrNull;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.savedStaysTitle)),
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
                    color: AppTheme.secondary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_outline_rounded, size: 36, color: AppTheme.secondary),
                ),
                const SizedBox(height: 16),
                Text(tr.signInToViewFavorites, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  tr.favoritesSignInPrompt,
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

    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.savedStaysTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: tr.retry,
            onPressed: () => ref.refresh(favoritesListProvider),
          ),
        ],
      ),
      body: favoritesAsync.when(
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
                  'Impossible de charger les favoris',
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
                  onPressed: () => ref.refresh(favoritesListProvider),
                  child: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 52,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr.noFavoritesYet,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Appuyez sur le cœur d\'une annonce en Algérie pour l\'ajouter à votre liste de favoris.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/explore');
                      },
                      icon: const Icon(Icons.search_rounded),
                      label: Text(tr.navExplore),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(favoritesListProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final property = favorites[index];
                return _FavoritePropertyCard(property: property);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoritePropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _FavoritePropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/properties/${property.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with heart button
            Stack(
              children: [
                AkriliImage(
                  imageUrl: property.coverUrl,
                  height: 180,
                  width: double.infinity,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: AppTheme.secondary, size: 20),
                      tooltip: 'Retirer des favoris',
                      onPressed: () async {
                        try {
                          await ref
                              .read(favoriteRepositoryProvider)
                              .toggleFavorite(property.id);
                          ref.invalidate(favoritesListProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                if (property.instantBooking)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            tr.instantBookingBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Property Info
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (property.averageRating != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              property.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? ""}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${property.capacity} ${tr.guestsUnit} • ${property.bedrooms} ${tr.bedroomsUnit} • ${property.bathrooms} ${tr.bathroomsUnit}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${NumberFormat("#,###").format(property.nightlyPrice)} DZD ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: '/ ${tr.nightsUnit.replaceAll("s", "")}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/properties/${property.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(tr.viewDetails, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
