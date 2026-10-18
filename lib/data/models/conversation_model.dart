class MessageModel {
  final int id;
  final int userId;
  final String body;
  final bool isMe;
  final String senderName;
  final DateTime? readAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.userId,
    required this.body,
    required this.isMe,
    required this.senderName,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      isMe: json['is_me'] as bool? ?? false,
      senderName: json['sender_name'] as String? ?? 'User',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

class ConversationModel {
  final int id;
  final String otherParticipantName;
  final String? propertyTitle;
  final String? coverUrl;
  final List<MessageModel> messages;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    required this.otherParticipantName,
    this.propertyTitle,
    this.coverUrl,
    required this.messages,
    this.lastMessageAt,
  });
}
