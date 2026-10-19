import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:akrili/core/api/api_client.dart';
import 'package:akrili/core/api/api_error_helper.dart';
import 'package:akrili/core/localization/app_localizations.dart';
import 'package:akrili/data/models/user_model.dart';
import 'package:akrili/data/models/property_model.dart';
import 'package:akrili/data/models/booking_model.dart';
import 'package:akrili/data/models/notification_model.dart';
import 'package:akrili/data/models/review_model.dart';
import 'package:akrili/core/theme/app_theme.dart';
import 'package:akrili/core/storage/secure_storage_service.dart';
import 'package:akrili/providers/theme_provider.dart';
import 'package:akrili/providers/property_provider.dart';

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

      expect(notification.title, equals('Demande de réservation'));
      expect(notification.deepLinkType, equals('booking'));
      expect(notification.deepLinkId, equals('42'));
    });

    test('ApiClient.resolveUrl correctly remaps local and .test image URLs', () {
      final old = ApiClient.activeBaseUrl;
      ApiClient.activeBaseUrl = 'http://10.0.2.2:8000';
      try {
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
        const externalUrl = 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750';
        expect(ApiClient.resolveUrl(externalUrl), equals(externalUrl));

        // Test null or empty
        expect(ApiClient.resolveUrl(null), isNull);
        expect(ApiClient.resolveUrl('   '), isNull);

        // Test staging URL resolution (HTTPS, no port 8000)
        ApiClient.activeBaseUrl = 'https://akrili.fawatirs.com';
        expect(
          ApiClient.resolveUrl('http://akrili.test:8000/storage/media/16/image.webp'),
          equals('https://akrili.fawatirs.com/storage/media/16/image.webp'),
        );
        expect(
          ApiClient.resolveUrl('http://akrili.fawatirs.com/storage/media/16/image.webp'),
          equals('https://akrili.fawatirs.com/storage/media/16/image.webp'),
        );
        expect(
          ApiClient.resolveUrl('/storage/media/16/image.webp'),
          equals('https://akrili.fawatirs.com/storage/media/16/image.webp'),
        );
      } finally {
        ApiClient.activeBaseUrl = old;
      }
    });

    test('PropertyModel resolves coverUrl and gallery from akrili.test to emulator host', () {
      final old = ApiClient.activeBaseUrl;
      ApiClient.activeBaseUrl = 'http://10.0.2.2:8000';
      try {
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
      } finally {
        ApiClient.activeBaseUrl = old;
      }
    });

    test('PropertyFilterState activeCount and copyWith work as expected', () {
      const initial = PropertyFilterState();
      expect(initial.activeCount, equals(0));
      expect(initial.hasActiveFilters, isFalse);

      final withWilaya = initial.copyWith(
        wilayaId: 16,
        wilayaName: 'Alger',
        search: 'villa',
      );
      expect(withWilaya.activeCount, equals(2));
      expect(withWilaya.hasActiveFilters, isTrue);

      final withPriceAndType = withWilaya.copyWith(
        type: 'villa',
        rentalMode: 'seasonal',
        minPrice: 5000,
        maxPrice: 20000,
        capacity: 4,
      );
      // search (1) + wilaya (1) + type (1) + rentalMode (1) + price (1) + capacity (1) = 6
      expect(withPriceAndType.activeCount, equals(6));

      final clearedRentalMode = withPriceAndType.copyWith(clearRentalMode: true);
      expect(clearedRentalMode.rentalMode, isNull);
      expect(clearedRentalMode.activeCount, equals(5));

      final clearedWilaya = withPriceAndType.copyWith(clearWilaya: true);
      expect(clearedWilaya.wilayaId, isNull);
      expect(clearedWilaya.wilayaName, isNull);
      expect(clearedWilaya.search, equals('villa'));
    });

    test('AppLocalizations defaults to French and provides correct translations', () {
      final frLoc = AppLocalizations(const Locale('fr'));
      expect(frLoc.languageCode, equals('fr'));
      expect(frLoc.navExplore, equals('Explorer'));
      expect(frLoc.navBookings, equals('Réservations'));
      expect(frLoc.navFavorites, equals('Favoris'));
      expect(frLoc.navProfile, equals('Profil'));
      expect(frLoc.perNightLabel, equals('DZD / nuit'));
      expect(frLoc.rentalMode, equals('Mode de location'));
      expect(frLoc.modeSeasonal, equals('Saisonnier'));
      expect(frLoc.modeYearly, equals('À l\'année'));
      expect(frLoc.modeBoth, equals('Les deux'));
      expect(frLoc.confirmAndBook, equals('Confirmer et réserver'));

      final arLoc = AppLocalizations(const Locale('ar'));
      expect(arLoc.navExplore, equals('استكشاف'));
      expect(arLoc.navBookings, equals('حجوزاتي'));

      final enLoc = AppLocalizations(const Locale('en'));
      expect(enLoc.navExplore, equals('Explore'));
      expect(enLoc.navBookings, equals('Bookings'));

      // Unknown locale falls back to French
      final deLoc = AppLocalizations(const Locale('de'));
      expect(deLoc.navExplore, equals('Explorer'));
      expect(deLoc.navBookings, equals('Réservations'));
    });

    test('ApiErrorHelper parses Laravel validation errors and status codes correctly', () {
      final tr = AppLocalizations(const Locale('fr'));

      // 1. Laravel 422 with errors map
      final dio422WithErrors = DioException(
        requestOptions: RequestOptions(path: '/api/v1/bookings'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/bookings'),
          statusCode: 422,
          data: {
            'message': 'The given data was invalid.',
            'errors': {
              'check_out': ['Le séjour minimum est de 5 nuit(s).'],
            },
          },
        ),
      );
      expect(ApiErrorHelper.parse(dio422WithErrors, tr), equals('Le séjour minimum est de 5 nuit(s).'));

      // 2. 422 with message only
      final dio422WithMessage = DioException(
        requestOptions: RequestOptions(path: '/api/v1/bookings'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/bookings'),
          statusCode: 422,
          data: {
            'message': 'Certaines dates sélectionnées ne sont plus disponibles.',
          },
        ),
      );
      expect(ApiErrorHelper.parse(dio422WithMessage, tr), equals('Certaines dates sélectionnées ne sont plus disponibles.'));

      // 3. 403 own property
      final dio403 = DioException(
        requestOptions: RequestOptions(path: '/api/v1/bookings'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/bookings'),
          statusCode: 403,
          data: {
            'message': 'Vous ne pouvez pas réserver votre propre logement.',
          },
        ),
      );
      expect(ApiErrorHelper.parse(dio403, tr), equals('Vous ne pouvez pas réserver votre propre logement.'));

      // 4. Connection timeout
      final dioTimeout = DioException(
        requestOptions: RequestOptions(path: '/api/v1/bookings'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(ApiErrorHelper.parse(dioTimeout, tr), equals(tr.connectionTimeoutMsg));

      // 5. Connection error
      final dioConnError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/bookings'),
        type: DioExceptionType.connectionError,
      );
      expect(ApiErrorHelper.parse(dioConnError, tr), equals(tr.cannotConnectMsg));

      // 6. Generic non-dio exception
      expect(ApiErrorHelper.parse(Exception('Quelque chose s\'est mal passé')), equals('Quelque chose s\'est mal passé'));
    });
  });

  group('Akrili Theme & Dark/Light Mode Tests', () {
    test('AppTheme brand primary does not use logo teal/emerald', () {
      const oldTeal = Color(0xFF0D9488);
      const oldEmerald = Color(0xFF059669);
      expect(AppTheme.primary, isNot(equals(oldTeal)));
      expect(AppTheme.primary, isNot(equals(oldEmerald)));
      expect(AppTheme.primary, equals(const Color(0xFF4F46E5)));
    });

    test('Light theme and Dark theme configurations are valid and distinct', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));

      expect(light.scaffoldBackgroundColor, equals(AppTheme.backgroundLight));
      expect(dark.scaffoldBackgroundColor, equals(AppTheme.backgroundDark));

      expect(light.cardColor, equals(AppTheme.surfaceLight));
      expect(dark.cardColor, equals(AppTheme.surfaceDark));

      expect(light.colorScheme.primary, equals(AppTheme.primary));
      expect(dark.colorScheme.primary, equals(AppTheme.primary));
    });

    test('ThemeModeNotifier transitions and persists states correctly', () async {
      final storage = _FakeSecureStorageService();
      final notifier = ThemeModeNotifier(storage);

      // Default state
      expect(notifier.state, equals(ThemeMode.system));

      // Switch to light
      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));
      expect(await storage.getThemeMode(), equals('light'));

      // Switch to dark
      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));
      expect(await storage.getThemeMode(), equals('dark'));

      // Switch back to system
      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
      expect(await storage.getThemeMode(), equals('system'));

      // Initial loading from saved dark
      final darkStorage = _FakeSecureStorageService('dark');
      final darkNotifier = ThemeModeNotifier(darkStorage);
      await pumpEventQueue();
      expect(darkNotifier.state, equals(ThemeMode.dark));
    });

    test('Theme localizations exist and are properly localized', () {
      final trFr = AppLocalizations(const Locale('fr'));
      expect(trFr.themeModeSetting, isNotEmpty);
      expect(trFr.chooseThemeTitle, isNotEmpty);
      expect(trFr.themeLight, equals('Mode Clair'));
      expect(trFr.themeDark, equals('Mode Sombre'));
      expect(trFr.themeSystem, contains('Système'));

      final trAr = AppLocalizations(const Locale('ar'));
      expect(trAr.themeLight, isNotEmpty);
      expect(trAr.themeDark, isNotEmpty);
      expect(trAr.themeSystem, isNotEmpty);

      final trEn = AppLocalizations(const Locale('en'));
      expect(trEn.themeLight, equals('Light Mode'));
      expect(trEn.themeDark, equals('Dark Mode'));
      expect(trEn.themeSystem, equals('System Default'));
    });
  });

  group('Akrili Airbnb Reviews & Ratings Tests', () {
    test('ReviewModel and EligibleBookingModel deserialization work correctly', () {
      final review = ReviewModel.fromJson({
        'id': 101,
        'rating': 5,
        'comment': 'Séjour parfait ! Appartement propre et hôte très accueillant.',
        'reply': 'Merci beaucoup pour votre visite !',
        'replied_at': '2026-08-20T10:00:00Z',
        'created_at': '2026-08-19T14:30:00Z',
        'created_at_formatted': '19/08/2026',
        'user': {
          'id': 12,
          'name': 'Samir Benali',
        },
      });

      expect(review.id, equals(101));
      expect(review.rating, equals(5));
      expect(review.comment, contains('Séjour parfait'));
      expect(review.reply, equals('Merci beaucoup pour votre visite !'));
      expect(review.userName, equals('Samir Benali'));
      expect(review.userId, equals(12));

      final eligible = EligibleBookingModel.fromJson({
        'id': 55,
        'reference': 'BK-78901',
        'check_in': '10/08/2026',
        'check_out': '15/08/2026',
      });

      expect(eligible.id, equals(55));
      expect(eligible.reference, equals('BK-78901'));
      expect(eligible.checkIn, equals('10/08/2026'));
      expect(eligible.checkOut, equals('15/08/2026'));
    });

    test('PropertyModel parses reviews, rating distribution, and eligible booking correctly', () {
      final property = PropertyModel.fromJson({
        'id': 20,
        'title': 'Appartement vue mer à Oran',
        'type': 'apartment',
        'status': 'published',
        'capacity': 4,
        'bedrooms': 2,
        'bathrooms': 1,
        'instant_booking': true,
        'nightly_price': 9000,
        'cleaning_fee': 1500,
        'deposit': 0,
        'min_nights': 1,
        'average_rating': 4.9,
        'reviews_count': 12,
        'rating_distribution': {
          '5': 10,
          '4': 2,
          '3': 0,
          '2': 0,
          '1': 0,
        },
        'eligible_booking': {
          'id': 77,
          'reference': 'BK-ELIGIBLE-1',
          'check_in': '01/09/2026',
          'check_out': '05/09/2026',
        },
        'reviews': [
          {
            'id': 1,
            'rating': 5,
            'comment': 'Magnifique séjour, propreté irréprochable.',
            'created_at_formatted': '06/09/2026',
            'user': {'id': 3, 'name': 'Amine'},
          }
        ],
      });

      expect(property.averageRating, equals(4.9));
      expect(property.reviewsCount, equals(12));
      expect(property.reviews.length, equals(1));
      expect(property.reviews.first.userName, equals('Amine'));
      expect(property.ratingDistribution[5], equals(10));
      expect(property.eligibleBooking, isNotNull);
      expect(property.eligibleBooking?.reference, equals('BK-ELIGIBLE-1'));
    });

    test('Review localizations exist for all supported languages', () {
      final trFr = AppLocalizations(const Locale('fr'));
      expect(trFr.reviewsTitle, equals('Évaluations & Avis'));
      expect(trFr.guestFavoriteBadge, equals('Coup de cœur voyageurs'));
      expect(trFr.writeReviewBtn, equals('Rédiger un avis'));
      expect(trFr.ratingLabel5, equals('Exceptionnel'));

      final trAr = AppLocalizations(const Locale('ar'));
      expect(trAr.reviewsTitle, isNotEmpty);
      expect(trAr.guestFavoriteBadge, isNotEmpty);
      expect(trAr.writeReviewBtn, isNotEmpty);
      expect(trAr.ratingLabel5, equals('ممتاز'));

      final trEn = AppLocalizations(const Locale('en'));
      expect(trEn.reviewsTitle, equals('Reviews & Ratings'));
      expect(trEn.guestFavoriteBadge, equals('Guest favorite'));
      expect(trEn.writeReviewBtn, equals('Write a Review'));
      expect(trEn.ratingLabel5, equals('Exceptional'));
    });
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  _FakeSecureStorageService([String? initialTheme]) {
    if (initialTheme != null) {
      _data['app_theme_mode'] = initialTheme;
    }
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    _data['app_theme_mode'] = mode;
  }

  @override
  Future<String?> getThemeMode() async {
    return _data['app_theme_mode'];
  }
}

