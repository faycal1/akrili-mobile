import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/property_model.dart';
import '../data/repositories/favorite_repository.dart';
import 'auth_provider.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return FavoriteRepository(client: client);
});

final favoritesListProvider = FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return await repo.getFavorites();
});
