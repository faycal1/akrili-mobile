import '../../core/api/api_client.dart';
import 'user_model.dart';

class WilayaModel {
  final int id;
  final String? code;
  final String name;

  WilayaModel({required this.id, this.code, required this.name});

  factory WilayaModel.fromJson(Map<String, dynamic> json) {
    var rawName = json['name'] ?? json['label'];
    String resolvedName = 'Wilaya';
    if (rawName is String) {
      resolvedName = rawName;
    } else if (rawName is Map) {
      resolvedName = rawName['fr']?.toString() ??
          rawName['en']?.toString() ??
          rawName['ar']?.toString() ??
          'Wilaya';
    }

    return WilayaModel(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString(),
      name: resolvedName,
    );
  }
}

class CommuneModel {
  final int id;
  final String name;

  CommuneModel({required this.id, required this.name});

  factory CommuneModel.fromJson(Map<String, dynamic> json) {
    var rawName = json['name'] ?? json['label'];
    String resolvedName = 'Commune';
    if (rawName is String) {
      resolvedName = rawName;
    } else if (rawName is Map) {
      resolvedName = rawName['fr']?.toString() ??
          rawName['en']?.toString() ??
          rawName['ar']?.toString() ??
          'Commune';
    }

    return CommuneModel(
      id: json['id'] as int? ?? 0,
      name: resolvedName,
    );
  }
}

class AmenityModel {
  final int id;
  final String name;
  final String? icon;

  AmenityModel({required this.id, required this.name, this.icon});

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }
}

class PropertyModel {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String? rentalMode;
  final String status;
  final int capacity;
  final int bedrooms;
  final int bathrooms;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool instantBooking;
  final int nightlyPrice;
  final int cleaningFee;
  final int deposit;
  final int minNights;
  final String? coverUrl;
  final List<String> gallery;
  final WilayaModel? wilaya;
  final CommuneModel? commune;
  final List<AmenityModel> amenities;
  final UserModel? owner;
  final double? averageRating;
  final int reviewsCount;
  final bool isFavorite;
  final DateTime? createdAt;

  PropertyModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.rentalMode,
    required this.status,
    required this.capacity,
    required this.bedrooms,
    required this.bathrooms,
    this.address,
    this.latitude,
    this.longitude,
    required this.instantBooking,
    required this.nightlyPrice,
    required this.cleaningFee,
    required this.deposit,
    required this.minNights,
    this.coverUrl,
    required this.gallery,
    this.wilaya,
    this.commune,
    required this.amenities,
    this.owner,
    this.averageRating,
    required this.reviewsCount,
    required this.isFavorite,
    this.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    var rawTitle = json['title'];
    String resolvedTitle = 'Property';
    if (rawTitle is String) {
      resolvedTitle = rawTitle;
    } else if (rawTitle is Map) {
      resolvedTitle = rawTitle['fr']?.toString() ??
          rawTitle['en']?.toString() ??
          rawTitle['ar']?.toString() ??
          'Property';
    }

    var rawDesc = json['description'];
    String? resolvedDesc;
    if (rawDesc is String) {
      resolvedDesc = rawDesc;
    } else if (rawDesc is Map) {
      resolvedDesc = rawDesc['fr']?.toString() ??
          rawDesc['en']?.toString() ??
          rawDesc['ar']?.toString();
    }

    return PropertyModel(
      id: json['id'] as int,
      title: resolvedTitle,
      description: resolvedDesc,
      type: json['type'] as String? ?? 'apartment',
      rentalMode: json['rental_mode'] as String?,
      status: json['status'] as String? ?? 'published',
      capacity: json['capacity'] as int? ?? 1,
      bedrooms: json['bedrooms'] as int? ?? 1,
      bathrooms: json['bathrooms'] as int? ?? 1,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      instantBooking: json['instant_booking'] as bool? ?? false,
      nightlyPrice: json['nightly_price'] as int? ?? 0,
      cleaningFee: json['cleaning_fee'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      minNights: json['min_nights'] as int? ?? 1,
      coverUrl: ApiClient.resolveUrl(json['cover_url'] as String?),
      gallery: (json['gallery'] as List<dynamic>?)
              ?.map((e) => ApiClient.resolveUrl(e.toString()) ?? e.toString())
              .toList() ??
          [],
      wilaya: json['wilaya'] != null && json['wilaya'] is Map<String, dynamic>
          ? WilayaModel.fromJson(json['wilaya'] as Map<String, dynamic>)
          : null,
      commune: json['commune'] != null && json['commune'] is Map<String, dynamic>
          ? CommuneModel.fromJson(json['commune'] as Map<String, dynamic>)
          : null,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => AmenityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      owner: json['owner'] != null && json['owner'] is Map<String, dynamic>
          ? UserModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
