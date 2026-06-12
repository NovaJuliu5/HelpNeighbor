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
    final adresse = (service.adresse?.isNotEmpty == true) ? service.adresse! : 'Adresse non renseignée';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _voirProfil(context),
          behavior: HitTestBehavior.opaque,
          child: CircleAvatar(
            backgroundImage: (service.photoUrl != null && service.photoUrl!.isNotEmpty)
                ? NetworkImage(service.photoUrl!)
                : null,
            child: (service.photoUrl == null || service.photoUrl!.isEmpty)
                ? Text(service.utilisateurNom[0])
                : null,
          ),
        ),
        title: Text(service.titre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.utilisateurNom),
            Row(
              children: [
                EtoilesEvaluation(note: service.noteMoyenne, taille: 14),
                const SizedBox(width: 4),
                Text(service.noteMoyenne.toStringAsFixed(1)), // nombre d'avis supprimé
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adresse,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Text(service.categorie, style: const TextStyle(fontSize: 12)),
            Text('${service.prix} Ar/h', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.flag_outlined, size: 20),
              onPressed: () => _signaler(context, ref),
              tooltip: 'Signaler',
            ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () => _contacter(context, ref),
              tooltip: 'Contacter',
            ),
          ],
        ),
        onTap: () => context.push('/service/${service.id}'),
      ),
    );
  }
}