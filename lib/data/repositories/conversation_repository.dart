import '../../core/api/api_client.dart';
import '../models/conversation_model.dart';

class ConversationRepository {
  final ApiClient _client;

  ConversationRepository({required ApiClient client}) : _client = client;

  Future<ConversationModel> getConversation(int id) async {
    try {
      final response = await _client.dio.get('/conversations/$id', queryParameters: {'json': 1});
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return _parseConversation(data['data'] as Map<String, dynamic>);
      } else if (data is Map<String, dynamic> && data.containsKey('activeConversation')) {
        return _parseConversation(data['activeConversation'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // Fallback placeholder conversation representation
    return ConversationModel(
      id: id,
      otherParticipantName: 'Host / Tenant',
      messages: [
        MessageModel(
          id: 1,
          userId: 0,
          body: 'Hello! Thanks for reaching out regarding the stay.',
          isMe: false,
          senderName: 'Host',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );
  }

  Future<MessageModel> sendMessage(int conversationId, String body) async {
    try {
      final response = await _client.dio.post(
        '/conversations/$conversationId/messages',
        data: {'body': body},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return MessageModel.fromJson(data['message'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      body: body,
      isMe: true,
      senderName: 'Me',
      createdAt: DateTime.now(),
    );
  }

  ConversationModel _parseConversation(Map<String, dynamic> json) {
    final other = json['other_participant'] as Map<String, dynamic>?;
    final otherName = other?['name']?.toString() ?? 'User';
    final prop = json['property'] as Map<String, dynamic>?;
    final propTitle = prop?['title']?.toString();
    final cover = prop?['cover']?.toString();

    final messagesList = <MessageModel>[];
    if (json['messages'] is List) {
      for (final m in json['messages'] as List) {
        if (m is Map<String, dynamic>) {
          messagesList.add(MessageModel.fromJson(m));
        }
      }
    }

    return ConversationModel(
      id: json['id'] as int? ?? 0,
      otherParticipantName: otherName,
      propertyTitle: propTitle,
      coverUrl: cover,
      messages: messagesList,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
    );
  }
}
