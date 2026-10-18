import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import 'auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BookingRepository(client: client);
});

final guestBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return await repo.getGuestBookings();
});

final hostBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return await repo.getHostBookings();
});

final bookingDetailProvider = FutureProvider.family<BookingModel, int>((ref, id) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return await repo.getBooking(id);
});
