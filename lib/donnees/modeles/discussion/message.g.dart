// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      expediteurId: json['expediteurId'] as String,
      contenu: json['contenu'] as String,
      typeMessage: json['typeMessage'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      estLu: json['estLu'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'expediteurId': instance.expediteurId,
      'contenu': instance.contenu,
      'typeMessage': instance.typeMessage,
      'mediaUrl': instance.mediaUrl,
      'estLu': instance.estLu,
      'createdAt': instance.createdAt.toIso8601String(),
    };
