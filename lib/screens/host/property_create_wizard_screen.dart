import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/property_draft_provider.dart';
import '../../providers/property_provider.dart';

class PropertyCreateWizardScreen extends ConsumerStatefulWidget {
  /// When set, the wizard edits an existing (draft/rejected) property
  /// instead of creating a new one.
  final int? propertyId;

  const PropertyCreateWizardScreen({super.key, this.propertyId});

  @override
  ConsumerState<PropertyCreateWizardScreen> createState() =>
      _PropertyCreateWizardScreenState();
}

class _PropertyCreateWizardScreenState
    extends ConsumerState<PropertyCreateWizardScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loadingExisting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.propertyId != null) {
      _loadingExisting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final property = await ref
              .read(propertyRepositoryProvider)
              .getProperty(widget.propertyId!);
          ref.read(propertyDraftProvider.notifier).loadForEdit(property);
        } catch (e) {
          _loadError = e.toString().replaceFirst('Exception: ', '');
        } finally {
          if (mounted) setState(() => _loadingExisting = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final draft = ref.watch(propertyDraftProvider);
    final notifier = ref.read(propertyDraftProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // While loading an existing property for editing, show a spinner.
    if (_loadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // If successfully submitted, show the completed pending state screen
    if (draft.submitStage == SubmitStage.completed) {
      return _buildSuccessScreen(context, tr, draft);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(draft.isEditing ? tr.editProperty : tr.listYourProperty),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _confirmCancel(context, tr);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Header Progress
            _buildStepIndicator(context, tr, draft.currentStep),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepView(context, tr, draft, notifier, isDark),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomBar(context, tr, draft, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
      BuildContext context, AppLocalizations tr, int currentStep) {
    final stepLabels = [
      tr.stepBasics,
      tr.stepLocation,
      tr.stepDetails,
      tr.stepPricing,
      tr.stepPhotos,
      tr.stepReview,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${currentStep + 1} sur 6',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                stepLabels[currentStep],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 6,
              minHeight: 6,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    switch (draft.currentStep) {
      case 0:
        return _buildStep1Basics(context, tr, draft, notifier, isDark);
      case 1:
        return _buildStep2Location(context, tr, draft, notifier, isDark);
      case 2:
        return _buildStep3Details(context, tr, draft, notifier, isDark);
      case 3:
        return _buildStep4Pricing(context, tr, draft, notifier, isDark);
      case 4:
        return _buildStep5Photos(context, tr, draft, notifier, isDark);
      case 5:
        return _buildStep6Review(context, tr, draft, notifier, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ================= STEP 1: BASICS =================
  Widget _buildStep1Basics(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    final types = [
      {'key': 'apartment', 'label': tr.typeApartment, 'icon': Icons.apartment_rounded},
      {'key': 'villa', 'label': tr.typeVilla, 'icon': Icons.villa_rounded},
      {'key': 'studio', 'label': tr.typeStudio, 'icon': Icons.single_bed_rounded},
      {'key': 'chalet', 'label': 'Chalet', 'icon': Icons.cabin_rounded},
      {'key': 'hotel', 'label': 'Hôtel', 'icon': Icons.hotel_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Quel type de logement proposez-vous ?',
          subtitle: 'Choisissez la catégorie correspondant le mieux à votre bien.',
        ),
        const SizedBox(height: 14),

        // Type selection grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((item) {
            final isSelected = draft.type == item['key'];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => notifier.updateBasics(type: item['key'] as String),
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.08)
                      : (isDark ? Colors.grey[900] : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 32,
                      color: isSelected ? AppTheme.primary : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),
        _buildSectionHeader(
          title: 'Donnez un titre à votre annonce',
          subtitle: 'Le titre en français est obligatoire. L\'arabe et l\'anglais sont optionnels.',
        ),
        const SizedBox(height: 14),

        TextFormField(
          initialValue: draft.titleFr,
          decoration: InputDecoration(
            labelText: tr.titleFrRequired,
            hintText: 'ex. Bel appartement vue mer à Tipaza',
            prefixIcon: const Icon(Icons.title_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateBasics(titleFr: val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: draft.titleAr,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText: tr.titleArOptional,
            hintText: 'مثال: شقة رائعة مطلة على البحر',
            prefixIcon: const Icon(Icons.language_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateBasics(titleAr: val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: draft.titleEn,
          decoration: InputDecoration(
            labelText: tr.titleEnOptional,
            hintText: 'e.g. Stunning apartment with sea view',
            prefixIcon: const Icon(Icons.translate_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateBasics(titleEn: val),
        ),

        const SizedBox(height: 28),
        _buildSectionHeader(
          title: 'Décrivez votre hébergement',
          subtitle: 'Présentez les points forts, la vue, le quartier et l\'ambiance générale.',
        ),
        const SizedBox(height: 14),

        TextFormField(
          initialValue: draft.descriptionFr,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: tr.descriptionFr,
            hintText: 'Description détaillée en français...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateBasics(descriptionFr: val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: draft.descriptionAr,
          maxLines: 3,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText: tr.descriptionAr,
            hintText: 'وصف المسكن بالعربية...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateBasics(descriptionAr: val),
        ),
      ],
    );
  }

  // ================= STEP 2: LOCATION =================
  Widget _buildStep2Location(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    final wilayasAsync = ref.watch(wilayasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Où se situe votre logement ?',
          subtitle: 'Sélectionnez la wilaya et la commune correspondante.',
        ),
        const SizedBox(height: 16),

        // Wilaya dropdown
        wilayasAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Text('Erreur wilayas: $err'),
          data: (wilayas) {
            return DropdownButtonFormField<int>(
              value: draft.wilayaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Wilaya *',
                prefixIcon: const Icon(Icons.map_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: wilayas.map((w) {
                return DropdownMenuItem<int>(
                  value: w.id,
                  child: Text('${w.code != null ? "${w.code} - " : ""}${w.name}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final selected = wilayas.firstWhere((w) => w.id == val);
                  notifier.setWilaya(selected.id, selected.name);
                }
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Dependent Commune dropdown
        if (draft.wilayaId == null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr.chooseWilayaFirst,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          Consumer(
            builder: (context, ref, child) {
              final communesAsync = ref.watch(communesProvider(draft.wilayaId!));
              return communesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Erreur communes: $err'),
                data: (communes) {
                  return DropdownButtonFormField<int>(
                    value: draft.communeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Commune *',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: communes.map((c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final selected = communes.firstWhere((c) => c.id == val);
                        notifier.setCommune(selected.id, selected.name);
                      }
                    },
                  );
                },
              );
            },
          ),

        const SizedBox(height: 24),
        _buildSectionHeader(
          title: 'Adresse et coordonnées',
          subtitle: 'Adresse précise pour faciliter l\'arrivée des voyageurs.',
        ),
        const SizedBox(height: 14),

        TextFormField(
          initialValue: draft.address,
          decoration: InputDecoration(
            labelText: tr.addressOptional,
            hintText: 'ex. Boulevard de l\'ALN, Résidence El Bahdja',
            prefixIcon: const Icon(Icons.home_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => notifier.updateLocationDetails(address: val),
        ),

        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: draft.latitude != null ? '${draft.latitude}' : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Latitude (-90..90)',
                  prefixIcon: const Icon(Icons.my_location_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) {
                  final num = double.tryParse(val);
                  notifier.updateLocationDetails(latitude: num);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: draft.longitude != null ? '${draft.longitude}' : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Longitude (-180..180)',
                  prefixIcon: const Icon(Icons.explore_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) {
                  final num = double.tryParse(val);
                  notifier.updateLocationDetails(longitude: num);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 3: DETAILS =================
  Widget _buildStep3Details(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    final rentalModes = [
      {'key': 'seasonal', 'label': tr.modeSeasonal},
      {'key': 'yearly', 'label': tr.modeYearly},
      {'key': 'both', 'label': tr.modeBoth},
    ];

    // Reference options for amenities and house rules
    final optionsAsync = ref.watch(hostPropertyOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Capacité & Pièces',
          subtitle: 'Indiquez le nombre de personnes et de pièces.',
        ),
        const SizedBox(height: 14),

        _buildCounterTile(
          context,
          title: tr.capacityLabel,
          value: draft.capacity,
          minValue: 1,
          maxValue: 100,
          onChanged: (val) => notifier.updateDetails(capacity: val),
        ),
        const SizedBox(height: 10),
        _buildCounterTile(
          context,
          title: tr.bedroomsLabel,
          value: draft.bedrooms,
          minValue: 0,
          maxValue: 50,
          onChanged: (val) => notifier.updateDetails(bedrooms: val),
        ),
        const SizedBox(height: 10),
        _buildCounterTile(
          context,
          title: tr.bathroomsLabel,
          value: draft.bathrooms,
          minValue: 0,
          maxValue: 50,
          onChanged: (val) => notifier.updateDetails(bathrooms: val),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader(
          title: tr.rentalMode,
          subtitle: 'Modalité de location proposée pour ce bien.',
        ),
        const SizedBox(height: 10),

        SegmentedButton<String>(
          segments: rentalModes.map((m) {
            return ButtonSegment<String>(
              value: m['key']!,
              label: Text(m['label']!),
            );
          }).toList(),
          selected: {draft.rentalMode},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              notifier.updateDetails(rentalMode: selected.first);
            }
          },
        ),

        const SizedBox(height: 28),
        _buildSectionHeader(
          title: tr.amenitiesTitle,
          subtitle: 'Sélectionnez les équipements disponibles pour les voyageurs.',
        ),
        const SizedBox(height: 12),

        optionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildFallbackAmenities(draft, notifier),
          data: (options) {
            final rawAmenities = options['amenities'] as List<dynamic>? ?? [];
            if (rawAmenities.isEmpty) {
              return _buildFallbackAmenities(draft, notifier);
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rawAmenities.map((item) {
                final id = item['id'] as int;
                final nameMap = item['name'];
                String name = 'Amenity';
                if (nameMap is Map) {
                  name = nameMap['fr']?.toString() ?? nameMap['en']?.toString() ?? 'Amenity';
                } else if (nameMap is String) {
                  name = nameMap;
                }
                final isSelected = draft.amenityIds.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (_) => notifier.toggleAmenity(id),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),
        _buildSectionHeader(
          title: tr.houseRulesTitle,
          subtitle: 'Précisez les règles et conditions applicables.',
        ),
        const SizedBox(height: 12),

        optionsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (options) {
            final rawRules = options['house_rules'] as List<dynamic>? ?? [];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rawRules.map((item) {
                final id = item['id'] as int;
                final nameMap = item['name'];
                String name = 'Rule';
                if (nameMap is Map) {
                  name = nameMap['fr']?.toString() ?? nameMap['en']?.toString() ?? 'Rule';
                } else if (nameMap is String) {
                  name = nameMap;
                }
                final isSelected = draft.houseRuleIds.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (_) => notifier.toggleHouseRule(id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFallbackAmenities(
      PropertyDraftState draft, PropertyDraftNotifier notifier) {
    final fallbacks = [
      {'id': 1, 'name': 'Wifi'},
      {'id': 2, 'name': 'Climatisation'},
      {'id': 3, 'name': 'Chauffage'},
      {'id': 4, 'name': 'Cuisine équipée'},
      {'id': 5, 'name': 'Parking gratuit'},
      {'id': 6, 'name': 'Télévision'},
      {'id': 7, 'name': 'Lave-linge'},
      {'id': 8, 'name': 'Piscine'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fallbacks.map((f) {
        final id = f['id'] as int;
        final isSelected = draft.amenityIds.contains(id);
        return FilterChip(
          label: Text(f['name'] as String),
          selected: isSelected,
          onSelected: (_) => notifier.toggleAmenity(id),
        );
      }).toList(),
    );
  }

  Widget _buildCounterTile(
    BuildContext context, {
    required String title,
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: value > minValue ? AppTheme.primary : Colors.grey,
                onPressed: value > minValue ? () => onChanged(value - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: value < maxValue ? AppTheme.primary : Colors.grey,
                onPressed: value < maxValue ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STEP 4: PRICING =================
  Widget _buildStep4Pricing(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Définissez vos tarifs',
          subtitle: 'Fixez votre prix de base par nuitée et les frais associés.',
        ),
        const SizedBox(height: 18),

        // Nightly Price
        TextFormField(
          initialValue: draft.nightlyPrice != null ? '${draft.nightlyPrice}' : '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${tr.nightlyPriceLabel} *',
            hintText: 'ex. 8000',
            prefixIcon: const Icon(Icons.attach_money_rounded),
            suffixText: 'DZD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            notifier.updatePricing(nightlyPrice: parsed);
          },
        ),

        const SizedBox(height: 14),

        // Min Nights
        TextFormField(
          initialValue: '${draft.minNights}',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Séjour minimum (nuits) *',
            hintText: 'ex. 1 ou 2',
            prefixIcon: const Icon(Icons.calendar_month_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null && parsed >= 1) {
              notifier.updatePricing(minNights: parsed);
            }
          },
        ),

        const SizedBox(height: 14),

        // Cleaning fee
        TextFormField(
          initialValue: draft.cleaningFee != null ? '${draft.cleaningFee}' : '0',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: tr.cleaningFeeLabel,
            hintText: 'ex. 1500',
            prefixIcon: const Icon(Icons.cleaning_services_rounded),
            suffixText: 'DZD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            notifier.updatePricing(cleaningFee: parsed ?? 0);
          },
        ),

        const SizedBox(height: 14),

        // Deposit
        TextFormField(
          initialValue: draft.deposit != null ? '${draft.deposit}' : '0',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: tr.depositLabel,
            hintText: 'ex. 10000',
            prefixIcon: const Icon(Icons.security_rounded),
            suffixText: 'DZD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            notifier.updatePricing(deposit: parsed ?? 0);
          },
        ),
      ],
    );
  }

  // ================= STEP 5: PHOTOS =================
  Widget _buildStep5Photos(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: tr.coverPhotoLabel,
          subtitle: tr.coverPhotoHint,
        ),
        const SizedBox(height: 12),

        // Cover Picker / Preview
        if (draft.cover == null && draft.existingCoverUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  draft.existingCoverUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.65),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    onPressed: () => _deleteExistingCover(context, tr, notifier),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.7),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(tr.edit),
                  onPressed: () async {
                    final photo = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1440,
                      imageQuality: 85,
                    );
                    if (photo != null) {
                      notifier.setCoverPhoto(photo);
                    }
                  },
                ),
              ),
            ],
          )
        else if (draft.cover == null)
          InkWell(
            onTap: () async {
              final photo = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                maxHeight: 1440,
                imageQuality: 85,
              );
              if (photo != null) {
                notifier.setCoverPhoto(photo);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.4),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, size: 44, color: AppTheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    tr.pickCover,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text('Image (max 8 Mo)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(draft.cover!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.65),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    onPressed: () => notifier.setCoverPhoto(null),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Photo Principale',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 28),
        _buildSectionHeader(
          title: '${tr.galleryPhotosLabel} (${draft.existingGallery.length + draft.gallery.length}/20)',
          subtitle: tr.galleryPhotosHint,
        ),
        const SizedBox(height: 12),

        // Gallery Photos Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Already-uploaded photos (edit mode): delete removes them server-side.
            ...draft.existingGallery.map((photo) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      photo.url,
                      width: 95,
                      height: 95,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 95,
                        height: 95,
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: const Icon(Icons.broken_image_outlined, size: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deleteExistingGalleryPhoto(context, tr, notifier, photo.id),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            ...draft.gallery.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(file.path),
                      width: 95,
                      height: 95,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => notifier.removeGalleryPhoto(idx),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Add more photos button
            if (draft.existingGallery.length + draft.gallery.length < 20)
              InkWell(
                onTap: () async {
                  final photos = await _picker.pickMultiImage(
                    maxWidth: 1920,
                    maxHeight: 1440,
                    imageQuality: 85,
                  );
                  if (photos.isNotEmpty) {
                    notifier.addGalleryPhotos(photos);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.primary),
                      SizedBox(height: 4),
                      Text('Ajouter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 6: REVIEW & SUBMIT =================
  Widget _buildStep6Review(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Vérifiez et soumettez votre annonce',
          subtitle: 'Une fois soumise, elle sera examinée par notre équipe avant publication.',
        ),
        const SizedBox(height: 18),

        // Summary Card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (draft.cover != null)
                Image.file(
                  File(draft.cover!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  height: 120,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BROUILLON → EN ATTENTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        Text(
                          '${NumberFormat("#,###").format(draft.nightlyPrice ?? 0)} DZD / nuit',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      draft.titleFr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${draft.communeName ?? ""}, ${draft.wilayaName ?? "Algérie"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(Icons.people_outline_rounded, '${draft.capacity} voy.'),
                        _buildDetailItem(Icons.bed_outlined, '${draft.bedrooms} ch.'),
                        _buildDetailItem(Icons.bathtub_outlined, '${draft.bathrooms} sdb'),
                        _buildDetailItem(Icons.photo_library_outlined, '${draft.gallery.length + (draft.cover != null ? 1 : 0)} photos'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Error message if any
        if (draft.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    draft.errorMessage!,
                    style: const TextStyle(color: AppTheme.secondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // Submitting indicator
        if (draft.submitStage != SubmitStage.idle && draft.submitStage != SubmitStage.error)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStageMessage(draft.submitStage, tr),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: draft.uploadProgress,
                    minHeight: 5,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getStageMessage(SubmitStage stage, AppLocalizations tr) {
    switch (stage) {
      case SubmitStage.creatingDraft:
        return tr.creatingDraftStatus;
      case SubmitStage.uploadingPhotos:
        return tr.uploadingPhotosStatus;
      case SubmitStage.submittingForReview:
        return tr.submittingStatus;
      default:
        return 'Traitement en cours...';
    }
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ================= SUCCESS SCREEN =================
  Widget _buildSuccessScreen(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.18),
                        AppTheme.primary.withOpacity(0.12),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr.propertySubmittedSuccess,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        'STATUT : EN ATTENTE DE VALIDATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr.propertySubmittedPendingMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(propertyDraftProvider.notifier).reset();
                      context.go('/host');
                    },
                    child: Text(
                      tr.viewMyListings,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _buildBottomBar(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftState draft,
    PropertyDraftNotifier notifier,
  ) {
    final isLastStep = draft.currentStep == 5;
    final canProceed = draft.isStepValid(draft.currentStep);
    final isSubmitting = draft.submitStage != SubmitStage.idle &&
        draft.submitStage != SubmitStage.error &&
        draft.submitStage != SubmitStage.completed;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (draft.currentStep > 0 && !isSubmitting)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => notifier.previousStep(),
                child: Text(tr.prevStepBtn),
              ),
            ),
          if (draft.currentStep > 0 && !isSubmitting) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (!canProceed || isSubmitting)
                  ? null
                  : () {
                      if (isLastStep) {
                        notifier.submit();
                      } else {
                        notifier.nextStep();
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep
                          ? (draft.isEditing ? tr.saveChanges : tr.submitForReviewBtn)
                          : tr.nextStepBtn,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  /// Deletes the already-uploaded cover photo server-side (edit mode).
  Future<void> _deleteExistingCover(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftNotifier notifier,
  ) async {
    final confirmed = await _confirmPhotoDelete(context, tr);
    if (confirmed != true) {
      return;
    }
    try {
      await notifier.removeExistingCover();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.serverErrorMsg)),
        );
      }
    }
  }

  /// Deletes a specific already-uploaded gallery photo server-side (edit mode).
  Future<void> _deleteExistingGalleryPhoto(
    BuildContext context,
    AppLocalizations tr,
    PropertyDraftNotifier notifier,
    int mediaId,
  ) async {
    final confirmed = await _confirmPhotoDelete(context, tr);
    if (confirmed != true) {
      return;
    }
    try {
      await notifier.removeExistingGalleryPhoto(mediaId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.serverErrorMsg)),
        );
      }
    }
  }

  /// Confirmation dialog shared by the existing-photo delete actions.
  Future<bool?> _confirmPhotoDelete(BuildContext context, AppLocalizations tr) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tr.deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, AppLocalizations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner l\'annonce ?'),
        content: const Text(
          'Les informations saisies ne seront pas enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(propertyDraftProvider.notifier).reset();
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
