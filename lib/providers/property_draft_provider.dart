import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_error_helper.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'property_provider.dart';

enum SubmitStage {
  idle,
  creatingDraft,
  uploadingPhotos,
  submittingForReview,
  completed,
  error,
}

class PropertyDraftState {
  final int currentStep;

  // Step 1 Basics
  final String type; // apartment, villa, studio, chalet, hotel
  final String titleFr;
  final String titleAr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionAr;
  final String descriptionEn;

  // Step 2 Location
  final int? wilayaId;
  final String? wilayaName;
  final int? communeId;
  final String? communeName;
  final String address;
  final double? latitude;
  final double? longitude;

  // Step 3 Details
  final int capacity;
  final int bedrooms;
  final int bathrooms;
  final String rentalMode; // seasonal, yearly, both
  final Set<int> amenityIds;
  final Set<int> houseRuleIds;

  // Step 4 Pricing
  final int? nightlyPrice;
  final int minNights;
  final int? cleaningFee;
  final int? deposit;

  // Step 5 Photos
  final XFile? cover;
  final List<XFile> gallery;

  // Step 6 Submitting & Result
  final SubmitStage submitStage;
  final double uploadProgress;
  final String? errorMessage;
  final PropertyModel? createdProperty;

  // Edit mode: id of the property being edited (null = creating a new one),
  // and whether it already has a cover so step 5 doesn't force a re-upload.
  final int? editingPropertyId;
  final bool hasExistingCover;

  // Existing (already-uploaded) media shown during edit, with ids so the
  // owner can delete a specific photo server-side.
  final String? existingCoverUrl;
  final int? existingCoverId;
  final List<PropertyPhoto> existingGallery;

  const PropertyDraftState({
    this.currentStep = 0,
    this.type = 'apartment',
    this.titleFr = '',
    this.titleAr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.wilayaId,
    this.wilayaName,
    this.communeId,
    this.communeName,
    this.address = '',
    this.latitude,
    this.longitude,
    this.capacity = 2,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.rentalMode = 'seasonal',
    this.amenityIds = const {},
    this.houseRuleIds = const {},
    this.nightlyPrice = 5000,
    this.minNights = 1,
    this.cleaningFee = 0,
    this.deposit = 0,
    this.cover,
    this.gallery = const [],
    this.submitStage = SubmitStage.idle,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.createdProperty,
    this.editingPropertyId,
    this.hasExistingCover = false,
    this.existingCoverUrl,
    this.existingCoverId,
    this.existingGallery = const [],
  });

  bool get isEditing => editingPropertyId != null;

  bool get isStep1Valid => titleFr.trim().isNotEmpty && type.isNotEmpty;
  bool get isStep2Valid => wilayaId != null && communeId != null;
  bool get isStep3Valid => capacity >= 1 && bedrooms >= 0 && bathrooms >= 0 && rentalMode.isNotEmpty;
  bool get isStep4Valid => (nightlyPrice != null && nightlyPrice! >= 0) && minNights >= 1;
  bool get isStep5Valid => cover != null || hasExistingCover;

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
      case 3:
        return isStep4Valid;
      case 4:
        return isStep5Valid;
      case 5:
        return true;
      default:
        return false;
    }
  }

  PropertyDraftState copyWith({
    int? currentStep,
    String? type,
    String? titleFr,
    String? titleAr,
    String? titleEn,
    String? descriptionFr,
    String? descriptionAr,
    String? descriptionEn,
    int? wilayaId,
    String? wilayaName,
    int? communeId,
    String? communeName,
    String? address,
    double? latitude,
    double? longitude,
    bool clearWilaya = false,
    bool clearCommune = false,
    int? capacity,
    int? bedrooms,
    int? bathrooms,
    String? rentalMode,
    Set<int>? amenityIds,
    Set<int>? houseRuleIds,
    int? nightlyPrice,
    int? minNights,
    int? cleaningFee,
    int? deposit,
    XFile? cover,
    bool clearCover = false,
    List<XFile>? gallery,
    SubmitStage? submitStage,
    double? uploadProgress,
    String? errorMessage,
    bool clearError = false,
    PropertyModel? createdProperty,
    int? editingPropertyId,
    bool? hasExistingCover,
    String? existingCoverUrl,
    bool clearExistingCover = false,
    int? existingCoverId,
    List<PropertyPhoto>? existingGallery,
  }) {
    return PropertyDraftState(
      currentStep: currentStep ?? this.currentStep,
      type: type ?? this.type,
      titleFr: titleFr ?? this.titleFr,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      wilayaId: clearWilaya ? null : (wilayaId ?? this.wilayaId),
      wilayaName: clearWilaya ? null : (wilayaName ?? this.wilayaName),
      communeId: (clearWilaya || clearCommune) ? null : (communeId ?? this.communeId),
      communeName: (clearWilaya || clearCommune) ? null : (communeName ?? this.communeName),
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacity: capacity ?? this.capacity,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      rentalMode: rentalMode ?? this.rentalMode,
      amenityIds: amenityIds ?? this.amenityIds,
      houseRuleIds: houseRuleIds ?? this.houseRuleIds,
      nightlyPrice: nightlyPrice ?? this.nightlyPrice,
      minNights: minNights ?? this.minNights,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      deposit: deposit ?? this.deposit,
      cover: clearCover ? null : (cover ?? this.cover),
      gallery: gallery ?? this.gallery,
      submitStage: submitStage ?? this.submitStage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdProperty: createdProperty ?? this.createdProperty,
      editingPropertyId: editingPropertyId ?? this.editingPropertyId,
      hasExistingCover: hasExistingCover ?? this.hasExistingCover,
      existingCoverUrl: clearExistingCover ? null : (existingCoverUrl ?? this.existingCoverUrl),
      existingCoverId: clearExistingCover ? null : (existingCoverId ?? this.existingCoverId),
      existingGallery: existingGallery ?? this.existingGallery,
    );
  }
}

class PropertyDraftNotifier extends StateNotifier<PropertyDraftState> {
  final PropertyRepository _repository;
  final Ref _ref;

  PropertyDraftNotifier(this._repository, this._ref) : super(const PropertyDraftState());

  void setStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Prefill the draft from an existing property for editing. Keeps every
  /// locale and house rule so saving does not erase data the form didn't show.
  void loadForEdit(PropertyModel p) {
    state = PropertyDraftState(
      currentStep: 0,
      type: p.type,
      titleFr: p.titleTranslations['fr'] ?? p.title,
      titleAr: p.titleTranslations['ar'] ?? '',
      titleEn: p.titleTranslations['en'] ?? '',
      descriptionFr: p.descriptionTranslations['fr'] ?? (p.description ?? ''),
      descriptionAr: p.descriptionTranslations['ar'] ?? '',
      descriptionEn: p.descriptionTranslations['en'] ?? '',
      wilayaId: p.wilaya?.id,
      wilayaName: p.wilaya?.name,
      communeId: p.commune?.id,
      communeName: p.commune?.name,
      address: p.address ?? '',
      latitude: p.latitude,
      longitude: p.longitude,
      capacity: p.capacity,
      bedrooms: p.bedrooms,
      bathrooms: p.bathrooms,
      rentalMode: p.rentalMode ?? 'seasonal',
      amenityIds: p.amenities.map((a) => a.id).toSet(),
      houseRuleIds: p.houseRuleIds.toSet(),
      nightlyPrice: p.nightlyPrice,
      minNights: p.minNights,
      cleaningFee: p.cleaningFee,
      deposit: p.deposit,
      editingPropertyId: p.id,
      hasExistingCover: p.coverUrl != null && p.coverUrl!.isNotEmpty,
      existingCoverUrl: p.coverUrl,
      existingCoverId: p.coverMediaId,
      existingGallery: p.galleryPhotos,
    );
  }

  /// Delete an already-uploaded gallery photo on the server and drop it locally.
  Future<void> removeExistingGalleryPhoto(int mediaId) async {
    final id = state.editingPropertyId;
    if (id == null) {
      return;
    }
    await _repository.deleteHostPropertyMedia(id, mediaId);
    state = state.copyWith(
      existingGallery: state.existingGallery.where((p) => p.id != mediaId).toList(),
    );
  }

  /// Delete the existing cover on the server; step 5 then requires a new one.
  Future<void> removeExistingCover() async {
    final id = state.editingPropertyId;
    final coverId = state.existingCoverId;
    if (id == null || coverId == null) {
      return;
    }
    await _repository.deleteHostPropertyMedia(id, coverId);
    state = state.copyWith(clearExistingCover: true, hasExistingCover: false);
  }

  void nextStep() {
    if (state.currentStep < 5 && state.isStepValid(state.currentStep)) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // Step 1 Basics
  void updateBasics({
    String? type,
    String? titleFr,
    String? titleAr,
    String? titleEn,
    String? descriptionFr,
    String? descriptionAr,
    String? descriptionEn,
  }) {
    state = state.copyWith(
      type: type,
      titleFr: titleFr,
      titleAr: titleAr,
      titleEn: titleEn,
      descriptionFr: descriptionFr,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
    );
  }

  // Step 2 Location
  void setWilaya(int wilayaId, String wilayaName) {
    if (state.wilayaId != wilayaId) {
      state = state.copyWith(
        wilayaId: wilayaId,
        wilayaName: wilayaName,
        clearCommune: true,
      );
    }
  }

  void setCommune(int communeId, String communeName) {
    state = state.copyWith(
      communeId: communeId,
      communeName: communeName,
    );
  }

  void updateLocationDetails({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Step 3 Details
  void updateDetails({
    int? capacity,
    int? bedrooms,
    int? bathrooms,
    String? rentalMode,
  }) {
    state = state.copyWith(
      capacity: capacity,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      rentalMode: rentalMode,
    );
  }

  void toggleAmenity(int amenityId) {
    final updated = Set<int>.from(state.amenityIds);
    if (updated.contains(amenityId)) {
      updated.remove(amenityId);
    } else {
      updated.add(amenityId);
    }
    state = state.copyWith(amenityIds: updated);
  }

  void toggleHouseRule(int ruleId) {
    final updated = Set<int>.from(state.houseRuleIds);
    if (updated.contains(ruleId)) {
      updated.remove(ruleId);
    } else {
      updated.add(ruleId);
    }
    state = state.copyWith(houseRuleIds: updated);
  }

  // Step 4 Pricing
  void updatePricing({
    int? nightlyPrice,
    int? minNights,
    int? cleaningFee,
    int? deposit,
  }) {
    state = state.copyWith(
      nightlyPrice: nightlyPrice,
      minNights: minNights,
      cleaningFee: cleaningFee,
      deposit: deposit,
    );
  }

  // Step 5 Photos
  void setCoverPhoto(XFile? file) {
    state = state.copyWith(cover: file);
  }

  void addGalleryPhotos(List<XFile> files) {
    final updated = List<XFile>.from(state.gallery);
    for (final f in files) {
      if (updated.length < 20) {
        updated.add(f);
      }
    }
    state = state.copyWith(gallery: updated);
  }

  void removeGalleryPhoto(int index) {
    if (index >= 0 && index < state.gallery.length) {
      final updated = List<XFile>.from(state.gallery);
      updated.removeAt(index);
      state = state.copyWith(gallery: updated);
    }
  }

  // Step 6 Submit & Lifecycle
  Future<bool> submit() async {
    if (!state.isStep1Valid || !state.isStep2Valid || !state.isStep3Valid || !state.isStep4Valid) {
      state = state.copyWith(
        errorMessage: 'Veuillez vérifier les informations du formulaire.',
        submitStage: SubmitStage.error,
      );
      return false;
    }

    try {
      // 1. Create a new draft, or update the existing one when editing.
      state = state.copyWith(
        submitStage: SubmitStage.creatingDraft,
        uploadProgress: 0.1,
        clearError: true,
      );

      final payload = {
        'type': state.type,
        'title': {
          'fr': state.titleFr.trim(),
          if (state.titleAr.trim().isNotEmpty) 'ar': state.titleAr.trim(),
          if (state.titleEn.trim().isNotEmpty) 'en': state.titleEn.trim(),
        },
        'description': {
          if (state.descriptionFr.trim().isNotEmpty) 'fr': state.descriptionFr.trim(),
          if (state.descriptionAr.trim().isNotEmpty) 'ar': state.descriptionAr.trim(),
          if (state.descriptionEn.trim().isNotEmpty) 'en': state.descriptionEn.trim(),
        },
        if (state.address.trim().isNotEmpty) 'address': state.address.trim(),
        if (state.latitude != null) 'latitude': state.latitude,
        if (state.longitude != null) 'longitude': state.longitude,
        'wilaya_id': state.wilayaId,
        'commune_id': state.communeId,
        'capacity': state.capacity,
        'bedrooms': state.bedrooms,
        'bathrooms': state.bathrooms,
        'rental_mode': state.rentalMode,
        'amenities': state.amenityIds.toList(),
        'house_rules': state.houseRuleIds.toList(),
        'rate': {
          'nightly_price': state.nightlyPrice ?? 0,
          'min_nights': state.minNights,
          'cleaning_fee': state.cleaningFee ?? 0,
          'deposit': state.deposit ?? 0,
        },
      };

      final PropertyModel saved = state.isEditing
          ? await _repository.updateHostProperty(state.editingPropertyId!, payload)
          : await _repository.createHostProperty(payload);

      // 2. Upload media if the user picked any. On edit, existing photos are
      // kept; a new cover replaces the old one and new gallery items append.
      if (state.cover != null || state.gallery.isNotEmpty) {
        state = state.copyWith(
          submitStage: SubmitStage.uploadingPhotos,
          uploadProgress: 0.3,
        );

        await _repository.uploadHostPropertyMedia(
          saved.id,
          cover: state.cover,
          gallery: state.gallery,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final progress = 0.3 + (sent / total) * 0.4;
              state = state.copyWith(uploadProgress: progress);
            }
          },
        );
      }

      // 3. Submit for moderation review (draft/rejected -> pending)
      state = state.copyWith(
        submitStage: SubmitStage.submittingForReview,
        uploadProgress: 0.85,
      );

      final finalProperty = await _repository.submitHostProperty(saved.id);

      // Refresh host feed and the edited property's detail.
      _ref.invalidate(hostPropertiesProvider);
      _ref.invalidate(propertyDetailProvider(saved.id));

      state = state.copyWith(
        submitStage: SubmitStage.completed,
        uploadProgress: 1.0,
        createdProperty: finalProperty,
      );

      return true;
    } catch (e) {
      // Surface the backend's actual message (e.g. the failing validation
      // field on a 422) instead of a generic "DioException ... 422".
      state = state.copyWith(
        submitStage: SubmitStage.error,
        errorMessage: ApiErrorHelper.parse(e),
      );
      return false;
    }
  }

  void reset() {
    state = const PropertyDraftState();
  }
}

final propertyDraftProvider =
    StateNotifierProvider.autoDispose<PropertyDraftNotifier, PropertyDraftState>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  return PropertyDraftNotifier(repo, ref);
});
