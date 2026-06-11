// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modele_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModeleService _$ModeleServiceFromJson(Map<String, dynamic> json) =>
    ModeleService(
      id: json['id'] as String,
      utilisateurId: json['utilisateurId'] as String,
      categorieId: json['categorieId'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      disponible: json['disponible'] as bool,
      nombreVues: (json['nombreVues'] as num).toInt(),
      nombreClics: (json['nombreClics'] as num).toInt(),
      nombreFavoris: (json['nombreFavoris'] as num).toInt(),
      tauxReussite: (json['tauxReussite'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      publieLe: json['publieLe'] == null
          ? null
          : DateTime.parse(json['publieLe'] as String),
      expireLe: json['expireLe'] == null
          ? null
          : DateTime.parse(json['expireLe'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$ModeleServiceToJson(ModeleService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'utilisateurId': instance.utilisateurId,
      'categorieId': instance.categorieId,
      'titre': instance.titre,
      'description': instance.description,
      'disponible': instance.disponible,
      'nombreVues': instance.nombreVues,
      'nombreClics': instance.nombreClics,
      'nombreFavoris': instance.nombreFavoris,
      'tauxReussite': instance.tauxReussite,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'publieLe': instance.publieLe?.toIso8601String(),
      'expireLe': instance.expireLe?.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };
