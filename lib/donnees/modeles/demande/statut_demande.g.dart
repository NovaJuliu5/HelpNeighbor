// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statut_demande.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatutDemande _$StatutDemandeFromJson(Map<String, dynamic> json) =>
    StatutDemande(
      id: json['id'] as String,
      demandeId: json['demandeId'] as String,
      statut: json['statut'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StatutDemandeToJson(StatutDemande instance) =>
    <String, dynamic>{
      'id': instance.id,
      'demandeId': instance.demandeId,
      'statut': instance.statut,
      'createdAt': instance.createdAt.toIso8601String(),
    };
