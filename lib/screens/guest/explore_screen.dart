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

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const List<Map<String, dynamic>> _quickDestinations = [
    {'name': 'Alger', 'wilayaId': 16},
    {'name': 'Oran', 'wilayaId': 31},
    {'name': 'Béjaïa', 'wilayaId': 6},
    {'name': 'Tipaza', 'wilayaId': 42},
    {'name': 'Constantine', 'wilayaId': 25},
    {'name': 'Tlemcen', 'wilayaId': 13},
    {'name': 'Annaba', 'wilayaId': 23},
    {'name': 'Taghit', 'wilayaId': 8},
  ];

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'all', 'icon': Icons.auto_awesome_rounded},
    {'key': 'apartment', 'icon': Icons.apartment_rounded},
    {'key': 'villa', 'icon': Icons.holiday_village_rounded},
    {'key': 'studio', 'icon': Icons.single_bed_rounded},
    {'key': 'chalet', 'icon': Icons.beach_access_rounded},
    {'key': 'hotel', 'icon': Icons.castle_rounded},
  ];

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

  void _selectCategory(String? categoryKey) {
    HapticFeedback.selectionClick();
    final current = ref.read(propertyFilterProvider);
    final targetType = (categoryKey == null || categoryKey == 'all') ? null : categoryKey;
    ref.read(propertyFilterProvider.notifier).state = current.copyWith(
      type: targetType,
      clearType: targetType == null,
    );
  }

  void _selectQuickDestination(Map<String, dynamic> dest) {
    HapticFeedback.lightImpact();
    final current = ref.read(propertyFilterProvider);
    final wilayaId = dest['wilayaId'] as int;
    final name = dest['name'] as String;

    if (current.wilayaId == wilayaId) {
      ref.read(propertyFilterProvider.notifier).state = current.copyWith(
        clearWilaya: true,
        clearCommune: true,
      );
    } else {
      ref.read(propertyFilterProvider.notifier).state = current.copyWith(
        wilayaId: wilayaId,
        wilayaName: name,
        clearCommune: true,
      );
    }
  }

  void _showFilterModal() {
    HapticFeedback.lightImpact();
    final currentFilter = ref.read(propertyFilterProvider);
    final tr = context.tr;

    int? tempWilayaId = currentFilter.wilayaId;
    String? tempWilayaName = currentFilter.wilayaName;
    int? tempCommuneId = currentFilter.communeId;
    String? tempCommuneName = currentFilter.communeName;
    String? tempType = currentFilter.type;
    String? tempRentalMode = currentFilter.rentalMode;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.filtersTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempWilayaId = null;
                                  tempWilayaName = null;
                                  tempCommuneId = null;
                                  tempCommuneName = null;
                                  tempType = null;
                                  tempRentalMode = null;
                                  tempCapacity = 1;
                                  minPriceController.clear();
                                  maxPriceController.clear();
                                });
                              },
                              child: Text(
                                tr.clearAll,
                                style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          tr.wilayaLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        wilayasAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(
                            'Erreur wilayas: $e',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          data: (wilayas) {
                            return DropdownButtonFormField<int>(
                              value: tempWilayaId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: tr.selectWilaya,
                                prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                              ),
                              items: [
                                DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(tr.allWilayas),
                                ),
                                ...wilayas.map((w) {
                                  final code = (w.code ?? '${w.id}').padLeft(2, '0');
                                  return DropdownMenuItem<int>(
                                    value: w.id,
                                    child: Text(
                                      '$code - ${w.name}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (newWilayaId) {
                                setModalState(() {
                                  tempWilayaId = newWilayaId;
                                  tempCommuneId = null;
                                  tempCommuneName = null;
                                  if (newWilayaId != null) {
                                    final found = wilayas.firstWhere((w) => w.id == newWilayaId);
                                    tempWilayaName = found.name;
                                  } else {
                                    tempWilayaName = null;
                                  }
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (tempWilayaId != null && communesAsync != null)
                          communesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text(
                              'Erreur communes: $e',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            data: (communes) {
                              return DropdownButtonFormField<int>(
                                value: tempCommuneId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: tr.selectCommune,
                                  prefixIcon: const Icon(Icons.map_rounded, color: AppTheme.primary, size: 20),
                                ),
                                items: [
                                  DropdownMenuItem<int>(
                                    value: null,
                                    child: Text(tr.allCommunes),
                                  ),
                                  ...communes.map((c) {
                                    return DropdownMenuItem<int>(
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
                        Text(
                          tr.propertyType,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
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
                              selectedColor: AppTheme.primary.withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primary : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  tempType = (typeKey == 'all' || !selected) ? null : typeKey;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr.rentalMode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'all',
                            'seasonal',
                            'yearly',
                            'both',
                          ].map((modeKey) {
                            final isSelected = (tempRentalMode == null && modeKey == 'all') ||
                                (tempRentalMode == modeKey);
                            final label = modeKey == 'all'
                                ? tr.allRentalModes
                                : tr.rentalModeLabel(modeKey);

                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppTheme.primary.withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primary : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  tempRentalMode = (modeKey == 'all' || !selected) ? null : modeKey;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr.pricePerNight,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.minGuestsLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded),
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
                                    icon: const Icon(Icons.add_rounded),
                                    onPressed: () => setModalState(() => tempCapacity++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                              rentalMode: tempRentalMode,
                              clearRentalMode: tempRentalMode == null,
                              minPrice: minP,
                              maxPrice: maxP,
                              clearPrice: minP == null && maxP == null,
                              capacity: tempCapacity > 1 ? tempCapacity : null,
                              clearCapacity: tempCapacity <= 1,
                            );

                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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

  String _getCategoryLabel(String key, AppLocalizations tr) {
    switch (key) {
      case 'apartment':
        return tr.typeApartment;
      case 'villa':
        return tr.typeVilla;
      case 'studio':
        return tr.typeStudio;
      case 'chalet':
        return tr.typeBungalow;
      case 'hotel':
        return tr.typeTraditional;
      default:
        return tr.allTypes;
    }
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Akrili',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Séjours & locations en Algérie',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (authUser != null)
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.15),
                            AppTheme.primaryLight.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2),
                        ),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 17,
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
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  tr.signIn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  elevation: 0,
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                      ),
                      boxShadow: AppTheme.cardShadow,
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
                          fontSize: 13.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: AppTheme.primary,
                        ),
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: filterState.hasActiveFilters
                            ? AppTheme.primaryGradient
                            : null,
                        color: filterState.hasActiveFilters
                            ? null
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: filterState.hasActiveFilters
                              ? Colors.transparent
                              : (isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
                        ),
                        boxShadow: filterState.hasActiveFilters
                            ? AppTheme.primaryButtonShadow
                            : AppTheme.cardShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
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
                    ),
                    if (filterState.activeCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
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

          // Horizontal Categories Rail
          Container(
            height: 52,
            margin: const EdgeInsets.only(top: 4, bottom: 2),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final catKey = cat['key'] as String;
                final isSelected = (filterState.type == null && catKey == 'all') ||
                    (filterState.type == catKey);
                final label = _getCategoryLabel(catKey, tr);

                return Material(
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _selectCategory(catKey),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 17,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[300] : Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Algerian Destinations Quick Chips
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickDestinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final dest = _quickDestinations[index];
                final isSelected = filterState.wilayaId == dest['wilayaId'];

                return ActionChip(
                  avatar: Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  label: Text(
                    dest['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  backgroundColor: isSelected
                      ? AppTheme.primary
                      : Theme.of(context).cardColor,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onPressed: () => _selectQuickDestination(dest),
                );
              },
            ),
          ),

          // Active Filter Chips Horizontal Row
          if (filterState.hasActiveFilters)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filterState.search != null && filterState.search!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.search, size: 14),
                        label: Text('"${filterState.search}"', style: const TextStyle(fontSize: 11.5)),
                        onDeleted: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      ),
                    ),
                  if (filterState.wilayaId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.location_on, size: 14),
                        label: Text(
                          filterState.wilayaName ?? 'Wilaya #${filterState.wilayaId}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearWilaya: true);
                        },
                      ),
                    ),
                  if (filterState.communeId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.map, size: 14),
                        label: Text(
                          filterState.communeName ?? 'Commune #${filterState.communeId}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearCommune: true);
                        },
                      ),
                    ),
                  if (filterState.minPrice != null || filterState.maxPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(
                          '${filterState.minPrice ?? 0} - ${filterState.maxPrice != null ? '${filterState.maxPrice} DZD' : 'Max'}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearPrice: true);
                        },
                      ),
                    ),
                  if (filterState.capacity != null && filterState.capacity! > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(
                          '${filterState.capacity}+ ${tr.guestsUnit}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearCapacity: true);
                        },
                      ),
                    ),
                  if (filterState.rentalMode != null &&
                      filterState.rentalMode!.isNotEmpty &&
                      filterState.rentalMode != 'all')
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.key_rounded, size: 14),
                        label: Text(
                          tr.rentalModeLabel(filterState.rentalMode!),
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: () {
                          ref.read(propertyFilterProvider.notifier).state =
                              filterState.copyWith(clearRentalMode: true);
                        },
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: Text(tr.clearAll, style: const TextStyle(fontSize: 11.5)),
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
              color: AppTheme.primary,
              onRefresh: () async {
                await ref.read(propertiesFeedProvider.notifier).refresh();
              },
              child: Builder(
                builder: (context) {
                  if (feedState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (feedState.error != null && feedState.properties.isEmpty) {
                    return Center(
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
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              feedState.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () =>
                                  ref.read(propertiesFeedProvider.notifier).refresh(),
                              label: Text(tr.retry),
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
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_city_outlined,
                                size: 60,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              tr.noPropertiesFound,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filterState.hasActiveFilters
                                  ? tr.adjustFiltersPrompt
                                  : 'Aucun séjour disponible pour le moment.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 13.5),
                            ),
                            if (filterState.hasActiveFilters) ...[
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 18),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: feedState.properties.length +
                        (feedState.isLoadingMore || !feedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < feedState.properties.length) {
                        final property = feedState.properties[index];
                        return _PropertyCard(property: property);
                      }

                      if (feedState.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.primary,
                              ),
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
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.seenAllStays,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 5,
                                height: 5,
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

class _PropertyCard extends ConsumerStatefulWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  ConsumerState<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends ConsumerState<_PropertyCard>
    with SingleTickerProviderStateMixin {
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
    ref.read(propertiesFeedProvider.notifier).refresh();
    ref.invalidate(favoritesListProvider);
  }

  String _formatPropertyType(String type, AppLocalizations tr) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return tr.typeApartment;
      case 'villa':
        return tr.typeVilla;
      case 'studio':
        return tr.typeStudio;
      case 'chalet':
        return tr.typeBungalow;
      case 'hotel':
        return tr.typeTraditional;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final property = widget.property;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
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
            context.push('/properties/${property.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AkriliImage(
                    imageUrl: property.coverUrl,
                    height: 220,
                    width: double.infinity,
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
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            _formatPropertyType(property.type, tr),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (property.rentalMode != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              tr.rentalModeLabel(property.rentalMode!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (property.instantBooking)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 15),
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
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ScaleTransition(
                      scale: _heartScaleAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.92),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _onToggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                property.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: property.isFavorite
                                    ? AppTheme.secondary
                                    : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (property.averageRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
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
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.commune?.name ?? ""}, ${property.wilaya?.name ?? "Algérie"}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildSpecMiniItem(
                            Icons.people_alt_outlined,
                            '${property.capacity} ${tr.guestsUnit}',
                          ),
                          _buildSpecDot(),
                          _buildSpecMiniItem(
                            Icons.bed_outlined,
                            '${property.bedrooms} ch.',
                          ),
                          _buildSpecDot(),
                          _buildSpecMiniItem(
                            Icons.bathtub_outlined,
                            '${property.bathrooms} sdb',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${property.nightlyPrice} DZD',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              TextSpan(
                                text: ' / ${tr.nightsUnit.replaceAll("s", "")}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Voir',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                            ],
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

  Widget _buildSpecMiniItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
