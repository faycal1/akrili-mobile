import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/property_model.dart';

class FavoriteRepository {
  final ApiClient _client;

  FavoriteRepository({required ApiClient client}) : _client = client;

  Future<List<PropertyModel>> getFavorites({int page = 1}) async {
    final response = await _client.dio.get(
      ApiEndpoints.favorites,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleFavorite(int propertyId) async {
    final response = await _client.dio.post(
      ApiEndpoints.favorites,
      data: {'property_id': propertyId},
    );
    return response.data['favorited'] as bool? ?? false;
  }
}
