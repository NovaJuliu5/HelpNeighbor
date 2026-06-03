import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/domaine/entites/entite_utilisateur.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_utilisateur.dart';

final profilUtilisateurProvider = FutureProvider.family<EntiteUtilisateur, String>((ref, userId) async {
  final depot = getIt<DepotUtilisateur>();
  final result = await depot.obtenirProfil(userId);
  return result.fold(
        (echec) => throw Exception(echec.message),
        (utilisateur) => utilisateur,
  );
});