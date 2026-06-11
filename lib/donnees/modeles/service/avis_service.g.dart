// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avis_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvisService _$AvisServiceFromJson(Map<String, dynamic> json) => AvisService(
      id: json['id'] as String,
      auteurId: json['auteurId'] as String,
      cibleId: json['cibleId'] as String,
      serviceId: json['serviceId'] as String?,
      demandeId: json['demandeId'] as String?,
      commentaire: json['commentaire'] as String?,
      signalement: json['signalement'] as bool,
      motifSignalement: json['motifSignalement'] as String?,
      verifieParAdmin: json['verifieParAdmin'] as bool,
      reponse: json['reponse'] as String?,
      reponseLe: json['reponseLe'] == null
          ? null
          : DateTime.parse(json['reponseLe'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      noteGlobale: (json['noteGlobale'] as num).toInt(),
    );

Map<String, dynamic> _$AvisServiceToJson(AvisService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'auteurId': instance.auteurId,
      'cibleId': instance.cibleId,
      'serviceId': instance.serviceId,
      'demandeId': instance.demandeId,
      'commentaire': instance.commentaire,
      'signalement': instance.signalement,
      'motifSignalement': instance.motifSignalement,
      'verifieParAdmin': instance.verifieParAdmin,
      'reponse': instance.reponse,
      'reponseLe': instance.reponseLe?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'noteGlobale': instance.noteGlobale,
    };
