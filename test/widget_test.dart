import 'package:flutter_test/flutter_test.dart';
import 'package:akrili/core/api/api_client.dart';
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

    test('ApiClient.resolveUrl correctly remaps local and .test image URLs', () {
      // Test dev domains like akrili.test:8000
      final resolvedAkrili = ApiClient.resolveUrl('http://akrili.test:8000/storage/media/16/image.webp');
      expect(resolvedAkrili, equals('http://10.0.2.2:8000/storage/media/16/image.webp'));

      // Test localhost:8000
      final resolvedLocalhost = ApiClient.resolveUrl('http://localhost:8000/storage/media/16/image.webp');
      expect(resolvedLocalhost, equals('http://10.0.2.2:8000/storage/media/16/image.webp'));

      // Test 127.0.0.1:8000
      final resolved127 = ApiClient.resolveUrl('http://127.0.0.1:8000/storage/media/16/image.webp');
      expect(resolved127, equals('http://10.0.2.2:8000/storage/media/16/image.webp'));

      // Test relative paths
      final resolvedRelative = ApiClient.resolveUrl('/storage/media/16/image.webp');
      expect(resolvedRelative, equals('http://10.0.2.2:8000/storage/media/16/image.webp'));

      // Test external CDN URLs (preserved)
      final externalUrl = 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750';
      expect(ApiClient.resolveUrl(externalUrl), equals(externalUrl));

      // Test null or empty
      expect(ApiClient.resolveUrl(null), isNull);
      expect(ApiClient.resolveUrl('   '), isNull);
    });

    test('PropertyModel resolves coverUrl and gallery from akrili.test to emulator host', () {
      final property = PropertyModel.fromJson({
        'id': 16,
        'title': 'Luxury Penthouse',
        'type': 'apartment',
        'status': 'published',
        'nightly_price': 15000,
        'cover_url': 'http://akrili.test:8000/storage/media/16/conversions/card.webp',
        'gallery': [
          'http://akrili.test:8000/storage/media/17/detail.webp',
          '/storage/media/18/bedroom.webp',
        ],
      });

      expect(
        property.coverUrl,
        equals('http://10.0.2.2:8000/storage/media/16/conversions/card.webp'),
      );
      expect(
        property.gallery[0],
        equals('http://10.0.2.2:8000/storage/media/17/detail.webp'),
      );
      expect(
        property.gallery[1],
        equals('http://10.0.2.2:8000/storage/media/18/bedroom.webp'),
      );
    });
  });
}
