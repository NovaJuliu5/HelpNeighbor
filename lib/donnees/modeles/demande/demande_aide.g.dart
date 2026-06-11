// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_aide.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DemandeAide _$DemandeAideFromJson(Map<String, dynamic> json) => DemandeAide(
      id: json['id'] as String,
      utilisateurId: json['utilisateurId'] as String,
      categorieId: json['categorieId'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      nombreOffres: (json['nombreOffres'] as num).toInt(),
      nombreVues: (json['nombreVues'] as num).toInt(),
      estVerifiee: json['estVerifiee'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      expireLe: DateTime.parse(json['expireLe'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
    );

Map<String, dynamic> _$DemandeAideToJson(DemandeAide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'utilisateurId': instance.utilisateurId,
      'categorieId': instance.categorieId,
      'titre': instance.titre,
      'description': instance.description,
      'nombreOffres': instance.nombreOffres,
      'nombreVues': instance.nombreVues,
      'estVerifiee': instance.estVerifiee,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'expireLe': instance.expireLe.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
    };
