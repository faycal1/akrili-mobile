import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  });

  bool get isStep1Valid => titleFr.trim().isNotEmpty && type.isNotEmpty;
  bool get isStep2Valid => wilayaId != null && communeId != null;
  bool get isStep3Valid => capacity >= 1 && bedrooms >= 0 && bathrooms >= 0 && rentalMode.isNotEmpty;
  bool get isStep4Valid => (nightlyPrice != null && nightlyPrice! >= 0) && minNights >= 1;
  bool get isStep5Valid => cover != null;

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
      // 1. Create draft
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

      final createdDraft = await _repository.createHostProperty(payload);

      // 2. Upload media if available
      if (state.cover != null || state.gallery.isNotEmpty) {
        state = state.copyWith(
          submitStage: SubmitStage.uploadingPhotos,
          uploadProgress: 0.3,
        );

        await _repository.uploadHostPropertyMedia(
          createdDraft.id,
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

      // 3. Submit for moderation review (draft -> pending)
      state = state.copyWith(
        submitStage: SubmitStage.submittingForReview,
        uploadProgress: 0.85,
      );

      final finalProperty = await _repository.submitHostProperty(createdDraft.id);

      // Refresh host properties feed
      _ref.invalidate(hostPropertiesProvider);

      state = state.copyWith(
        submitStage: SubmitStage.completed,
        uploadProgress: 1.0,
        createdProperty: finalProperty,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        submitStage: SubmitStage.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
