import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/property_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/property_provider.dart';
import '../shared/widgets/akrili_image.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      ref.read(propertiesFeedProvider.notifier).loadNextPage();
    }
  }

  void _onSearchSubmitted(String query) {
    final current = ref.read(propertyFilterProvider);
    ref.read(propertyFilterProvider.notifier).state = current.copyWith(
      search: query.trim().isEmpty ? null : query.trim(),
      clearSearch: query.trim().isEmpty,
    );
  }

  void _showFilterModal() {
    final currentFilter = ref.read(propertyFilterProvider);
    final tr = context.tr;

    int? tempWilayaId = currentFilter.wilayaId;
    String? tempWilayaName = currentFilter.wilayaName;
    int? tempCommuneId = currentFilter.communeId;
    String? tempCommuneName = currentFilter.communeName;
    String? tempType = currentFilter.type;
    int tempCapacity = currentFilter.capacity ?? 1;
    final minPriceController = TextEditingController(
      text: currentFilter.minPrice != null ? '${currentFilter.minPrice}' : '',
    );
    final maxPriceController = TextEditingController(
      text: currentFilter.maxPrice != null ? '${currentFilter.maxPrice}' : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, modalRef, child) {
                final wilayasAsync = modalRef.watch(wilayasProvider);
                final communesAsync = tempWilayaId != null
                    ? modalRef.watch(communesProvider(tempWilayaId!))
                    : null;

                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.filtersTitle,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempWilayaId = null;
                                  tempWilayaName = null;
                                  tempCommuneId = null;
                                  tempCommuneName = null;
                                  tempType = null;
                                  tempCapacity = 1;
                                  minPriceController.clear();
                                  maxPriceController.clear();
                                });
                              },
                              child: Text(tr.clearAll),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 10),

                        // Wilaya Selector
                        Text(
                          tr.wilayaLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        wilayasAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (err, _) => Text(
                            'Could not load wilayas: $err',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          data: (wilayas) {
                            return DropdownButtonFormField<int?>(
                              value: tempWilayaId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: tr.selectWilaya,
                                prefixIcon: const Icon(Icons.location_on_outlined),
                              ),
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(tr.allWilayas),
                                ),

                                ...wilayas.map((w) {
                                  final displayName = w.code != null ? '${w.code} — ${w.name}' : w.name;
                                  return DropdownMenuItem<int?>(
                                    value: w.id,
                                    child: Text(displayName, overflow: TextOverflow.ellipsis),
                                  );
                                }),
                              ],
                              onChanged: (newWilayaId) {
                                setModalState(() {
                                  tempWilayaId = newWilayaId;
                                  if (newWilayaId != null) {
                                    final found = wilayas.firstWhere((w) => w.id == newWilayaId);
                                    tempWilayaName = found.name;
                                  } else {
                                    tempWilayaName = null;
                                  }
                                  // Reset commune when wilaya changes
                                  tempCommuneId = null;
                                  tempCommuneName = null;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Commune Selector
                        Text(
                          tr.communeLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        if (tempWilayaId == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  tr.chooseWilayaFirst,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else if (communesAsync != null)
                          communesAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (err, _) => Text(
                              'Could not load communes: $err',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            data: (communes) {
                              return DropdownButtonFormField<int?>(
                                value: tempCommuneId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: tr.allCommunes,
                                  prefixIcon: const Icon(Icons.map_outlined),
                                ),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(tr.allCommunes),
                                  ),
                                  ...communes.map((c) {
                                    return DropdownMenuItem<int?>(
                                      value: c.id,
                                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                                    );
                                  }),
                                ],
                                onChanged: (newCommuneId) {
                                  setModalState(() {
                                    tempCommuneId = newCommuneId;
                                    if (newCommuneId != null) {
                                      final found = communes.firstWhere((c) => c.id == newCommuneId);
                                      tempCommuneName = found.name;
                                    } else {
                                      tempCommuneName = null;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 18),

                        // Property Type
                        Text(
                          tr.propertyType,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'all',
                            'apartment',
                            'villa',
                            'studio',
                            'chalet',
                            'hotel',
                          ].map((typeKey) {
                            final isSelected = (tempType == null && typeKey == 'all') ||
                                (tempType == typeKey);
                            String label;
                            switch (typeKey) {
                              case 'apartment':
                                label = tr.typeApartment;
                                break;
                              case 'villa':
                                label = tr.typeVilla;
                                break;
                              case 'studio':
                                label = tr.typeStudio;
                                break;
                              case 'chalet':
                                label = tr.typeBungalow;
                                break;
                              case 'hotel':
                                label = tr.typeTraditional;
                                break;
                              default:
                                label = tr.allTypes;
                            }

                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  tempType = (typeKey == 'all' || !selected) ? null : typeKey;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Price Range
                        Text(
                          tr.pricePerNight,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min (DZD)',
                                  suffixText: 'DZD',
                                  hintText: '0',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max (DZD)',
                                  suffixText: 'DZD',
                                  hintText: 'Max',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Capacity / Guests
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.minGuestsLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: tempCapacity > 1
                                      ? () => setModalState(() => tempCapacity--)
                                      : null,
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 32),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$tempCapacity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setModalState(() => tempCapacity++),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Apply Button
                        ElevatedButton(
                          onPressed: () {
                            final minP = int.tryParse(minPriceController.text.trim());
                            final maxP = int.tryParse(maxPriceController.text.trim());

                            ref.read(propertyFilterProvider.notifier).state =
                                currentFilter.copyWith(
                              wilayaId: tempWilayaId,
                              wilayaName: tempWilayaName,
                              clearWilaya: tempWilayaId == null,
                              communeId: tempCommuneId,
                              communeName: tempCommuneName,
                              clearCommune: tempCommuneId == null,
                              type: tempType,
                              clearType: tempType == null,
                              minPrice: minP,
                              maxPrice: maxP,
                              clearPrice: minP == null && maxP == null,
                              capacity: tempCapacity > 1 ? tempCapacity : null,
                              clearCapacity: tempCapacity <= 1,
                            );

                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            tr.applyFilters,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(propertiesFeedProvider);
    final filterState = ref.watch(propertyFilterProvider);
    final authUser = ref.watch(authNotifierProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
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
            const Text(
              'Akrili',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          // Authentication header pill / avatar
          if (authUser != null)
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authUser.isHost ? tr.hostBadge : tr.guestBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        authUser.name.isNotEmpty ? authUser.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(tr.signIn, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => context.push('/login'),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Modern Search and Filter Bar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      onChanged: (val) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: tr.searchHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchSubmitted('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Filter button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: filterState.hasActiveFilters
                          ? AppTheme.primary
                          : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: filterState.hasActiveFilters
                              ? AppTheme.primary
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _showFilterModal,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.tune_rounded,
                            color: filterState.hasActiveFilters
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    if (filterState.activeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${filterState.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active Filter Chips Horizontal Row
          if (filterState.hasActiveFilters)
            Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filterState.search != null && filterState.search!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        avatar: const Icon(Icons.search, size: 16),
                        label: Text('"${filterState.search}"'),
                        onDeleted: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      ),
                    ),
                  if (filterState.wilayaId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        avatar: const Icon(Icons.location_on, size: 16),
                        label: Text(filterState.wilayaName ?? 'Wilaya #${filterState.wilayaId}'),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearWilaya: true);
                        },
                      ),
                    ),
                  if (filterState.communeId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        avatar: const Icon(Icons.map, size: 16),
                        label: Text(filterState.communeName ?? 'Commune #${filterState.communeId}'),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearCommune: true);
                        },
                      ),
                    ),
                  if (filterState.type != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(
                          filterState.type![0].toUpperCase() + filterState.type!.substring(1),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearType: true);
                        },
                      ),
                    ),
                  if (filterState.minPrice != null || filterState.maxPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(
                          '${filterState.minPrice ?? 0} - ${filterState.maxPrice != null ? '${filterState.maxPrice} DZD' : 'Any'}',
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearPrice: true);
                        },
                      ),
                    ),
                  if (filterState.capacity != null && filterState.capacity! > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text('${filterState.capacity}+ ${tr.guestsUnit}'),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearCapacity: true);
                        },
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(tr.clearAll, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(propertyFilterProvider.notifier).state =
                          const PropertyFilterState();
                    },
                  ),
                ],
              ),
            ),

          // Infinite Scrolling Properties Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(propertiesFeedProvider.notifier).refresh();
              },
              child: Builder(
                builder: (context) {
                  if (feedState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (feedState.error != null && feedState.properties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              feedState.error.toString(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  ref.read(propertiesFeedProvider.notifier).refresh(),
                              child: Text(tr.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (feedState.properties.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_city_outlined,
                              size: 64,
                              color: Colors.grey.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr.noPropertiesFound,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filterState.hasActiveFilters
                                  ? tr.adjustFiltersPrompt
                                  : 'Aucun séjour disponible pour le moment.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            if (filterState.hasActiveFilters) ...[
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(tr.clearAll),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(propertyFilterProvider.notifier).state =
                                      const PropertyFilterState();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: feedState.properties.length +
                        (feedState.isLoadingMore || !feedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < feedState.properties.length) {
                        final property = feedState.properties[index];
                        return _PropertyCard(property: property);
                      }

                      // Bottom Loader or End Indicator
                      if (feedState.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.seenAllStays,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;

    return GestureDetector(
      onTap: () {
        context.push('/properties/${property.id}');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                AkriliImage(
                  imageUrl: property.coverUrl,
                  height: 200,
                  width: double.infinity,
                ),
                // Favorite Heart Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        property.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: property.isFavorite ? AppTheme.secondary : Colors.black87,
                        size: 20,
                      ),
                      onPressed: () async {
                        final authUser = ref.read(authNotifierProvider).valueOrNull;
                        if (authUser == null) {
                          context.push('/login');
                          return;
                        }
                        final repo = ref.read(favoriteRepositoryProvider);
                        await repo.toggleFavorite(property.id);
                        ref.read(propertiesFeedProvider.notifier).refresh();
                        ref.invalidate(favoritesListProvider);
                      },
                    ),
                  ),
                ),
                // Instant Booking Badge
                if (property.instantBooking)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            tr.instantBookingBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (property.averageRating != null) ...[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          property.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algérie"} • ${property.capacity} ${tr.guestsUnit}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${property.nightlyPrice} DZD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        ' / ${tr.nightsUnit.replaceAll("s", "")}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
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
