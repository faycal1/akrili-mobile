class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final String? createdAtFormatted;
  final String userName;
  final int? userId;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.reply,
    this.repliedAt,
    this.createdAt,
    this.createdAtFormatted,
    required this.userName,
    this.userId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return ReviewModel(
      id: json['id'] as int? ?? 0,
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      reply: json['reply'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.tryParse(json['replied_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      createdAtFormatted: json['created_at_formatted'] as String?,
      userName: userMap?['name'] as String? ?? 'Voyageur',
      userId: userMap?['id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'reply': reply,
      'replied_at': repliedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'created_at_formatted': createdAtFormatted,
      'user': {
        'id': userId,
        'name': userName,
      },
    };
  }
}

class EligibleBookingModel {
  final int id;
  final String reference;
  final String? checkIn;
  final String? checkOut;

  EligibleBookingModel({
    required this.id,
    required this.reference,
    this.checkIn,
    this.checkOut,
  });

  factory EligibleBookingModel.fromJson(Map<String, dynamic> json) {
    return EligibleBookingModel(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'check_in': checkIn,
      'check_out': checkOut,
    };
  }
}
