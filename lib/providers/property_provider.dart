import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'auth_provider.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PropertyRepository(client: client);
});

class PropertyFilterState {
  final String? search;
  final int? wilayaId;
  final String? wilayaName;
  final int? communeId;
  final String? communeName;
  final int? capacity;
  final String? checkIn;
  final String? checkOut;
  final String? type;
  final int? minPrice;
  final int? maxPrice;

  const PropertyFilterState({
    this.search,
    this.wilayaId,
    this.wilayaName,
    this.communeId,
    this.communeName,
    this.capacity,
    this.checkIn,
    this.checkOut,
    this.type,
    this.minPrice,
    this.maxPrice,
  });

  int get activeCount {
    int count = 0;
    if (search != null && search!.trim().isNotEmpty) count++;
    if (wilayaId != null) count++;
    if (communeId != null) count++;
    if (type != null && type!.isNotEmpty && type != 'all') count++;
    if (minPrice != null || maxPrice != null) count++;
    if (capacity != null && capacity! > 1) count++;
    return count;
  }

  bool get hasActiveFilters => activeCount > 0;

  PropertyFilterState copyWith({
    String? search,
    bool clearSearch = false,
    int? wilayaId,
    String? wilayaName,
    int? communeId,
    String? communeName,
    int? capacity,
    String? checkIn,
    String? checkOut,
    String? type,
    int? minPrice,
    int? maxPrice,
    bool clearWilaya = false,
    bool clearCommune = false,
    bool clearType = false,
    bool clearPrice = false,
    bool clearCapacity = false,
  }) {
    return PropertyFilterState(
      search: clearSearch ? null : (search ?? this.search),
      wilayaId: clearWilaya ? null : (wilayaId ?? this.wilayaId),
      wilayaName: clearWilaya ? null : (wilayaName ?? this.wilayaName),
      communeId: (clearWilaya || clearCommune) ? null : (communeId ?? this.communeId),
      communeName: (clearWilaya || clearCommune) ? null : (communeName ?? this.communeName),
      capacity: clearCapacity ? null : (capacity ?? this.capacity),
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      type: clearType ? null : (type ?? this.type),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }
}

final propertyFilterProvider = StateProvider<PropertyFilterState>((ref) {
  return const PropertyFilterState();
});

class PropertiesFeedState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final Object? error;

  const PropertiesFeedState({
    this.properties = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  PropertiesFeedState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    Object? error,
    bool clearError = false,
  }) {
    return PropertiesFeedState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PropertiesFeedNotifier extends StateNotifier<PropertiesFeedState> {
  final PropertyRepository _repository;
  final Ref _ref;

  PropertiesFeedNotifier(this._repository, this._ref)
      : super(const PropertiesFeedState(isLoading: true)) {
    loadFirstPage();
    // Reactively reload on filter changes
    _ref.listen<PropertyFilterState>(
      propertyFilterProvider,
      (previous, next) {
        loadFirstPage();
      },
    );
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, page: 1, clearError: true);
    final filter = _ref.read(propertyFilterProvider);

    try {
      final items = await _repository.getProperties(
        search: filter.search,
        wilayaId: filter.wilayaId,
        communeId: filter.communeId,
        capacity: filter.capacity,
        checkIn: filter.checkIn,
        checkOut: filter.checkOut,
        type: filter.type,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        page: 1,
      );

      state = state.copyWith(
        properties: items,
        isLoading: false,
        page: 1,
        hasMore: items.length >= 15,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final filter = _ref.read(propertyFilterProvider);
    final nextPage = state.page + 1;

    try {
      final newItems = await _repository.getProperties(
        search: filter.search,
        wilayaId: filter.wilayaId,
        communeId: filter.communeId,
        capacity: filter.capacity,
        checkIn: filter.checkIn,
        checkOut: filter.checkOut,
        type: filter.type,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        page: nextPage,
      );

      state = state.copyWith(
        properties: [...state.properties, ...newItems],
        isLoadingMore: false,
        page: nextPage,
        hasMore: newItems.length >= 15,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e,
      );
    }
  }

  Future<void> refresh() async {
    await loadFirstPage();
  }
}

final propertiesFeedProvider =
    StateNotifierProvider<PropertiesFeedNotifier, PropertiesFeedState>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  return PropertiesFeedNotifier(repo, ref);
});

final wilayasProvider = FutureProvider<List<WilayaModel>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return await repo.getWilayas();
});

final communesProvider =
    FutureProvider.family<List<CommuneModel>, int>((ref, wilayaId) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return await repo.getCommunes(wilayaId);
});

final propertiesListProvider = FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  final filter = ref.watch(propertyFilterProvider);

  return await repo.getProperties(
    search: filter.search,
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
