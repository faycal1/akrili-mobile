import 'package:flutter_test/flutter_test.dart';
import 'package:akrili/data/models/user_model.dart';
import 'package:akrili/data/models/property_model.dart';
import 'package:akrili/data/models/booking_model.dart';
import 'package:akrili/data/models/notification_model.dart';

void main() {
  group('Akrili Models Unit Tests', () {
    test('UserModel role detection works correctly', () {
      final hostUser = UserModel.fromJson({
        'id': 1,
        'name': 'Owner User',
        'email': 'owner@akrili.com',
        'roles': ['owner'],
        'locale': 'fr',
        'is_verified': true,
      });

      expect(hostUser.isHost, isTrue);
      expect(hostUser.isGuest, isFalse);

      final tenantUser = UserModel.fromJson({
        'id': 2,
        'name': 'Tenant User',
        'email': 'tenant@akrili.com',
        'roles': ['tenant'],
        'locale': 'en',
        'is_verified': false,
      });

      expect(tenantUser.isHost, isFalse);
      expect(tenantUser.isGuest, isTrue);
    });

    test('PropertyModel json deserialization works correctly', () {
      final property = PropertyModel.fromJson({
        'id': 10,
        'title': 'Seaside Villa in Tipaza',
        'type': 'villa',
        'status': 'published',
        'capacity': 6,
        'bedrooms': 3,
        'bathrooms': 2,
        'instant_booking': true,
        'nightly_price': 12000,
        'cleaning_fee': 2000,
        'deposit': 5000,
        'min_nights': 2,
        'wilaya': {'id': 42, 'name': 'Tipaza'},
        'commune': {'id': 100, 'name': 'Tipaza Centre'},
      });

      expect(property.id, equals(10));
      expect(property.nightlyPrice, equals(12000));
      expect(property.instantBooking, isTrue);
      expect(property.wilaya?.name, equals('Tipaza'));
    });

    test('BookingModel status helpers work correctly', () {
      final booking = BookingModel.fromJson({
        'id': 5,
        'reference': 'BK-TEST-123',
        'status': 'pending',
        'check_in': '2026-07-01',
        'check_out': '2026-07-05',
        'guests': 2,
        'total_price': 48000,
        'can_decide': true,
        'can_review': false,
      });

      expect(booking.isPending, isTrue);
      expect(booking.isConfirmed, isFalse);
      expect(booking.canDecide, isTrue);
      expect(booking.totalPrice, equals(48000));
    });

    test('NotificationModel deep-link extraction works correctly', () {
      final notification = NotificationModel.fromJson({
        'id': 'notif-uuid-1',
        'type': 'BookingRequested',
        'data': {
          'type': 'booking',
          'booking_id': 42,
          'message': 'New booking requested for your listing',
        },
      });

      expect(notification.title, equals('Booking Requested'));
      expect(notification.deepLinkType, equals('booking'));
      expect(notification.deepLinkId, equals('42'));
    });
  });
}
