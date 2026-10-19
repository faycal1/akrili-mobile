import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final ApiClient _client;

  PropertyRepository({required ApiClient client}) : _client = client;

  Future<List<PropertyModel>> getProperties({
    String? search,
    int? wilayaId,
    int? communeId,
    int? capacity,
    String? checkIn,
    String? checkOut,
    String? type,
    String? rentalMode,
    int? minPrice,
    int? maxPrice,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (wilayaId != null) 'wilaya_id': wilayaId,
      if (communeId != null) 'commune_id': communeId,
      if (capacity != null) 'capacity': capacity,
      if (checkIn != null) 'check_in': checkIn,
      if (checkOut != null) 'check_out': checkOut,
      if (type != null && type.isNotEmpty && type != 'all') 'type': type,
      if (rentalMode != null && rentalMode.isNotEmpty && rentalMode != 'all') 'rental_mode': rentalMode,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };

    final response = await _client.dio.get(
      ApiEndpoints.properties,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<WilayaModel>> getWilayas() async {
    final response = await _client.dio.get(ApiEndpoints.wilayas);
    final data = response.data as List<dynamic>;
    return data.map((e) => WilayaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CommuneModel>> getCommunes(int wilayaId) async {
    final response = await _client.dio.get(ApiEndpoints.communes(wilayaId));
    final data = response.data as List<dynamic>;
    return data.map((e) => CommuneModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PropertyModel> getProperty(int id) async {
    final response = await _client.dio.get(ApiEndpoints.property(id));
    return PropertyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getPropertyAvailability(int id) async {
    final response = await _client.dio.get(ApiEndpoints.propertyAvailability(id));
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<PropertyModel>> getHostProperties({int page = 1}) async {
    final response = await _client.dio.get(
      ApiEndpoints.hostProperties,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PropertyModel> createHostProperty(Map<String, dynamic> data) async {
    final response = await _client.dio.post(
      ApiEndpoints.hostProperties,
      data: data,
    );
    return PropertyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PropertyModel> updateHostProperty(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put(
      ApiEndpoints.hostProperty(id),
      data: data,
    );
    return PropertyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PropertyModel> uploadHostPropertyMedia(
    int propertyId, {
    XFile? cover,
    List<XFile>? gallery,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final map = <String, dynamic>{};

    if (cover != null) {
      map['cover'] = await MultipartFile.fromFile(
        cover.path,
        filename: cover.name,
      );
    }

    if (gallery != null && gallery.isNotEmpty) {
      final galleryFiles = <MultipartFile>[];
      for (final file in gallery) {
        galleryFiles.add(await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ));
      }
      map['gallery'] = galleryFiles;
    }

    final formData = FormData.fromMap(map);

    final response = await _client.dio.post(
      ApiEndpoints.hostPropertyMedia(propertyId),
      data: formData,
      onSendProgress: onSendProgress,
    );

    return PropertyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteHostPropertyMedia(int propertyId, int mediaId) async {
    await _client.dio.delete(ApiEndpoints.hostPropertyDeleteMedia(propertyId, mediaId));
  }

  Future<PropertyModel> submitHostProperty(int propertyId) async {
    final response = await _client.dio.post(ApiEndpoints.hostPropertySubmit(propertyId));
    return PropertyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getHostPropertyOptions() async {
    final response = await _client.dio.get(ApiEndpoints.hostPropertyOptions);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
