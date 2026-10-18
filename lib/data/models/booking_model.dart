import 'property_model.dart';
import 'user_model.dart';

class BookingModel {
  final int id;
  final String reference;
  final String status;
  final String checkIn;
  final String checkOut;
  final int guests;
  final int totalPrice;
  final Map<String, dynamic>? priceBreakdown;
  final DateTime? expiresAt;
  final bool canDecide;
  final bool canReview;
  final PropertyModel? property;
  final UserModel? tenant;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.reference,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    this.priceBreakdown,
    this.expiresAt,
    required this.canDecide,
    required this.canReview,
    this.property,
    this.tenant,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      checkIn: json['check_in'] as String? ?? '',
      checkOut: json['check_out'] as String? ?? '',
      guests: json['guests'] as int? ?? 1,
      totalPrice: json['total_price'] as int? ?? 0,
      priceBreakdown: json['price_breakdown'] as Map<String, dynamic>?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      canDecide: json['can_decide'] as bool? ?? false,
      canReview: json['can_review'] as bool? ?? false,
      property: json['property'] != null && json['property'] is Map<String, dynamic>
          ? PropertyModel.fromJson(json['property'] as Map<String, dynamic>)
          : null,
      tenant: json['tenant'] != null && json['tenant'] is Map<String, dynamic>
          ? UserModel.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
