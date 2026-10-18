class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  String get title {
    switch (type) {
      case 'BookingRequested':
        return 'Booking Requested';
      case 'BookingAccepted':
        return 'Booking Confirmed';
      case 'BookingRejected':
        return 'Booking Declined';
      case 'MessageReceived':
        return 'New Message';
      default:
        return 'Notification';
    }
  }

  String get message {
    return data['message']?.toString() ??
        data['body']?.toString() ??
        'You have a new update';
  }

  String? get deepLinkType {
    if (type.contains('Booking')) return 'booking';
    if (type.contains('Message')) return 'conversation';
    return data['type']?.toString();
  }

  String? get deepLinkId {
    return data['booking_id']?.toString() ??
        data['conversation_id']?.toString() ??
        data['id']?.toString();
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
