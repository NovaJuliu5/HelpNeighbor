// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreferencesUtilisateur _$PreferencesUtilisateurFromJson(
        Map<String, dynamic> json) =>
    PreferencesUtilisateur(
      id: json['id'] as String,
      utilisateurId: json['utilisateurId'] as String,
      langue: json['langue'] as String,
      theme: json['theme'] as String,
      notificationsActives: json['notificationsActives'] as bool,
      notificationsEmail: json['notificationsEmail'] as bool,
      notificationsPush: json['notificationsPush'] as bool,
      rayonRechercheKm: (json['rayonRechercheKm'] as num).toInt(),
    );

Map<String, dynamic> _$PreferencesUtilisateurToJson(
        PreferencesUtilisateur instance) =>
    <String, dynamic>{
      'id': instance.id,
      'utilisateurId': instance.utilisateurId,
      'langue': instance.langue,
      'theme': instance.theme,
      'notificationsActives': instance.notificationsActives,
      'notificationsEmail': instance.notificationsEmail,
      'notificationsPush': instance.notificationsPush,
      'rayonRechercheKm': instance.rayonRechercheKm,
    };
