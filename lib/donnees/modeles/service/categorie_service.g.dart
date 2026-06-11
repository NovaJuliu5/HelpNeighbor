// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorie_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategorieService _$CategorieServiceFromJson(Map<String, dynamic> json) =>
    CategorieService(
      id: json['id'] as String,
      nom: json['nom'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icone: json['icone'] as String?,
      couleur: json['couleur'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ordre: (json['ordre'] as num).toInt(),
      estActive: json['estActive'] as bool,
      parentId: json['parentId'] as String?,
    );

Map<String, dynamic> _$CategorieServiceToJson(CategorieService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'slug': instance.slug,
      'description': instance.description,
      'icone': instance.icone,
      'couleur': instance.couleur,
      'imageUrl': instance.imageUrl,
      'ordre': instance.ordre,
      'estActive': instance.estActive,
      'parentId': instance.parentId,
    };
