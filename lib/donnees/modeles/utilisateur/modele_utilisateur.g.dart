// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modele_utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModeleUtilisateur _$ModeleUtilisateurFromJson(Map<String, dynamic> json) =>
    ModeleUtilisateur(
      id: json['id'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      motDePasseHash: json['mot_de_passe_hash'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$ModeleUtilisateurToJson(ModeleUtilisateur instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'telephone': instance.telephone,
      'mot_de_passe_hash': instance.motDePasseHash,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };
