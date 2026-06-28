import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/presentation/widgets/communs/etoiles_evaluation.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_conversation.dart';
import 'package:help_neighbor/donnees/depots/depot_signalement.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';

class CarteService extends ConsumerWidget {
  final EntiteService service;
  const CarteService({super.key, required this.service});

  void _voirProfil(BuildContext context) {
    print("Navigation vers le profil de : ${service.utilisateurId}");
    context.push('/profil/${service.utilisateurId}');
  }

  void _contacter(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final currentUserId = authState.utilisateur?.id;
    if (currentUserId == null) {
      context.showSnackBar('Vous devez être connecté', isError: true);
      return;
    }
    final depotConv = getIt<DepotConversation>();
    final result = await depotConv.creerConversation(
      service.utilisateurId,
      serviceId: service.id,
    );
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (convId) => context.push('/discussion/$convId', extra: {'autreNom': service.utilisateurNom}),
    );
  }

  Future<void> _signaler(BuildContext context, WidgetRef ref) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pourquoi signalez-vous ce contenu ?'),
        children: [
          SimpleDialogOption(child: const Text('Contenu inapproprié'), onPressed: () => Navigator.pop(ctx, 'inapproprié')),
          SimpleDialogOption(child: const Text('Spam'), onPressed: () => Navigator.pop(ctx, 'spam')),
          SimpleDialogOption(child: const Text('Harcèlement'), onPressed: () => Navigator.pop(ctx, 'harcèlement')),
          SimpleDialogOption(child: const Text('Fausse information'), onPressed: () => Navigator.pop(ctx, 'fausse_info')),
          const Divider(),
          SimpleDialogOption(child: const Text('Annuler'), onPressed: () => Navigator.pop(ctx, null)),
        ],
      ),
    );
    if (motif == null) return;
    final depot = getIt<DepotSignalement>();
    final result = await depot.signaler(
      cibleType: 'service',
      cibleId: service.id,
      motif: motif,
    );
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (msg) => context.showSnackBar(msg),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final adresse = (service.adresse?.isNotEmpty == true) ? service.adresse! : 'Adresse non renseignée';
    final prix = service.prix ?? 0;
    final note = service.noteMoyenne ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale : avatar + titre + icônes d'action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar cliquable pour voir le profil
                GestureDetector(
                  onTap: () => _voirProfil(context),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (service.photoUrl != null && service.photoUrl!.isNotEmpty)
                        ? NetworkImage(service.photoUrl!)
                        : null,
                    child: (service.photoUrl == null || service.photoUrl!.isEmpty)
                        ? Text(service.utilisateurNom.isNotEmpty ? service.utilisateurNom[0] : '?',
                        style: const TextStyle(fontSize: 20))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Informations du service
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.titre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'par ${service.utilisateurNom}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          EtoilesEvaluation(note: note, taille: 16),
                          const SizedBox(width: 4),
                          Text(
                            note.toStringAsFixed(1),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adresse,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Boutons d'action (signaler, contacter) en colonne
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, size: 22),
                      color: Colors.grey.shade600,
                      onPressed: () => _signaler(context, ref),
                      tooltip: 'Signaler',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, size: 22),
                      color: primaryColor,
                      onPressed: () => _contacter(context, ref),
                      tooltip: 'Contacter',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ligne des détails : catégorie + prix (distance supprimée)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      service.categorie ?? 'Sans catégorie',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '$prix Ar',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}