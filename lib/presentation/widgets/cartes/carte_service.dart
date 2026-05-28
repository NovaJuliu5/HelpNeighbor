import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/presentation/widgets/communs/etoiles_evaluation.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_conversation.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';

class CarteService extends ConsumerWidget {
  final EntiteService service;
  const CarteService({super.key, required this.service});

  void _voirProfil(BuildContext context) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ? Text(service.utilisateurNom.isNotEmpty ? service.utilisateurNom[0] : '?')
                : null,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(service.titre, style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Text('${service.distanceKm.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 12)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.utilisateurNom),
            Row(
              children: [
                EtoilesEvaluation(note: service.noteMoyenne, taille: 14),
                const SizedBox(width: 4),
                Text('${service.noteMoyenne.toStringAsFixed(1)} · ${service.nbAvis} avis'),
              ],
            ),
            Text(service.categorie, style: const TextStyle(fontSize: 12)),
            Text('${service.prix} Ar/h', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.message),
          onPressed: () => _contacter(context, ref),
          tooltip: 'Contacter',
        ),
        onTap: () => context.push('/service/${service.id}'),
      ),
    );
  }
}