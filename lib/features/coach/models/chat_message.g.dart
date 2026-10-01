// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  role: json['role'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) => <String, dynamic>{
  'role': instance.role,
  'content': instance.content,
};

ChatReply _$ChatReplyFromJson(Map<String, dynamic> json) => ChatReply(
  reply: json['reply'] as String? ?? '',
  usage: json['usage'] as Map<String, dynamic>?,
);
