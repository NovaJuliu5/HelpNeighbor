import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/donnees/depots/depot_authentification.dart';
import 'package:help_neighbor/donnees/depots/depot_utilisateur.dart';
import 'package:help_neighbor/donnees/depots/depot_service.dart';
import 'package:help_neighbor/donnees/depots/depot_demande.dart';
import 'package:help_neighbor/donnees/depots/depot_discussion.dart';
import 'package:help_neighbor/donnees/depots/depot_offre.dart';
import 'package:help_neighbor/donnees/depots/depot_conversation.dart';   // AJOUT
import 'package:help_neighbor/donnees/depots/depot_notification.dart';   // AJOUT (si vous avez un dépôt notification)
import 'package:help_neighbor/services/localisation/service_localisation.dart';
import 'package:help_neighbor/donnees/depots/depot_avis.dart';

final getIt = GetIt.instance;

Future<void> initDependances() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  getIt.registerSingleton<ClientApi>(ClientApi());
  getIt.registerSingleton<DepotAuthentification>(DepotAuthentification(getIt()));
  getIt.registerSingleton<DepotUtilisateur>(DepotUtilisateur(getIt()));
  getIt.registerSingleton<DepotService>(DepotService(getIt()));
  getIt.registerSingleton<DepotDemande>(DepotDemande(getIt()));
  getIt.registerSingleton<DepotDiscussion>(DepotDiscussion(getIt()));
  getIt.registerSingleton<DepotOffre>(DepotOffre(getIt()));               // AJOUT si nécessaire
  getIt.registerSingleton<DepotConversation>(DepotConversation(getIt())); // AJOUT
  getIt.registerSingleton<DepotNotification>(DepotNotification(getIt())); // AJOUT si nécessaire
  getIt.registerSingleton<ServiceLocalisation>(ServiceLocalisation());
  getIt.registerSingleton<DepotAvis>(DepotAvis(getIt()));
}