// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offre_demande.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OffreDemande _$OffreDemandeFromJson(Map<String, dynamic> json) => OffreDemande(
      id: json['id'] as String,
      demandeId: json['demandeId'] as String,
      prestataireId: json['prestataireId'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reponseLe: json['reponseLe'] == null
          ? null
          : DateTime.parse(json['reponseLe'] as String),
      prixPropose: (json['prixPropose'] as num?)?.toDouble(),
      delaiPropose: (json['delaiPropose'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OffreDemandeToJson(OffreDemande instance) =>
    <String, dynamic>{
      'id': instance.id,
      'demandeId': instance.demandeId,
      'prestataireId': instance.prestataireId,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
      'reponseLe': instance.reponseLe?.toIso8601String(),
      'prixPropose': instance.prixPropose,
      'delaiPropose': instance.delaiPropose,
    };
