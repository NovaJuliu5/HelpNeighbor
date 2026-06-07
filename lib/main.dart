import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:help_neighbor/app/app.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/config/environnement.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation
  await Environnement.init();
  await initDependances();

  // 🔍 LOGS : inspection des données persistantes avant nettoyage
  final prefs = await SharedPreferences.getInstance();
  print('📦 [MAIN] Toutes les clés SharedPreferences : ${prefs.getKeys()}');
  for (var key in prefs.getKeys()) {
    print('   $key = ${prefs.get(key)}');
  }

  final storage = const FlutterSecureStorage();
  final allStorage = await storage.readAll();
  print('🔐 [MAIN] Contenu FlutterSecureStorage : $allStorage');

  // 🗑️ Nettoyage forcé : suppression de toutes les données persistantes
  await prefs.clear();
  await storage.deleteAll();
  print('✅ [MAIN] Données persistantes effacées avec succès');

  // Lancement de l'application
  runApp(const ProviderScope(child: MyApp()));
}