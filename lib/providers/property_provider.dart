import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'auth_provider.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PropertyRepository(client: client);
});

class PropertyFilterState {
  final int? wilayaId;
  final int? communeId;
  final int? capacity;
  final String? checkIn;
  final String? checkOut;
  final String? type;
  final int? minPrice;
  final int? maxPrice;

  const PropertyFilterState({
    this.wilayaId,
    this.communeId,
    this.capacity,
    this.checkIn,
    this.checkOut,
    this.type,
    this.minPrice,
    this.maxPrice,
  });

  PropertyFilterState copyWith({
    int? wilayaId,
    int? communeId,
    int? capacity,
    String? checkIn,
    String? checkOut,
    String? type,
    int? minPrice,
    int? maxPrice,
    bool clearWilaya = false,
  }) {
    return PropertyFilterState(
      wilayaId: clearWilaya ? null : (wilayaId ?? this.wilayaId),
      communeId: clearWilaya ? null : (communeId ?? this.communeId),
      capacity: capacity ?? this.capacity,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      type: type ?? this.type,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

final propertyFilterProvider = StateProvider<PropertyFilterState>((ref) {
  return const PropertyFilterState();
});

final propertiesListProvider = FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  final filter = ref.watch(propertyFilterProvider);

  return await repo.getProperties(
    wilayaId: filter.wilayaId,
    communeId: filter.communeId,
    capacity: filter.capacity,
    checkIn: filter.checkIn,
    checkOut: filter.checkOut,
    type: filter.type,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
  );
});

final propertyDetailProvider = FutureProvider.family<PropertyModel, int>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return await repo.getProperty(id);
});

final propertyAvailabilityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return await repo.getPropertyAvailability(id);
});

final hostPropertiesProvider = FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return await repo.getHostProperties();
});
