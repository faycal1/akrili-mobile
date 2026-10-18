import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiClient _client;

  BookingRepository({required ApiClient client}) : _client = client;

  Future<List<BookingModel>> getGuestBookings({int page = 1}) async {
    final response = await _client.dio.get(
      ApiEndpoints.bookings,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> createBooking({
    required int propertyId,
    required String checkIn,
    required String checkOut,
    required int guests,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.bookings,
      data: {
        'property_id': propertyId,
        'check_in': checkIn,
        'check_out': checkOut,
        'guests': guests,
      },
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BookingModel> getBooking(int id) async {
    final response = await _client.dio.get(ApiEndpoints.booking(id));
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> getHostBookings({int page = 1}) async {
    final response = await _client.dio.get(
      ApiEndpoints.hostBookings,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> acceptBooking(int id) async {
    final response = await _client.dio.post(ApiEndpoints.acceptBooking(id));
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BookingModel> rejectBooking(int id, {String? reason}) async {
    final response = await _client.dio.post(
      ApiEndpoints.rejectBooking(id),
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> submitReview({
    required int bookingId,
    required int rating,
    required String comment,
  }) async {
    await _client.dio.post(
      ApiEndpoints.reviews,
      data: {
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
      },
    );
  }
}
