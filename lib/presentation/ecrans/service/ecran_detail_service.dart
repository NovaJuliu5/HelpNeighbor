import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_avis.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/presentation/widgets/communs/etoiles_evaluation.dart';
import 'package:help_neighbor/presentation/widgets/communs/dialogue_notation.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_service.dart';
import 'package:help_neighbor/donnees/depots/depot_conversation.dart';
import 'package:help_neighbor/donnees/depots/depot_avis.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';

final serviceDetailProvider = FutureProvider.family<EntiteService, String>((ref, id) async {
  final depot = getIt<DepotService>();
  final result = await depot.obtenirServiceParId(id);
  return result.fold(
        (echec) => throw Exception(echec.message),
        (service) => service,
  );
});

final avisServiceProvider = FutureProvider.family<List<EntiteAvis>, String>((ref, serviceId) async {
  final depot = getIt<DepotAvis>();
  final result = await depot.listerAvis(serviceId: serviceId);
  return result.fold((echec) => [], (avis) => avis);
});

class EcranDetailService extends ConsumerWidget {
  final String id;
  const EcranDetailService({super.key, required this.id});

  Future<void> _contacter(BuildContext context, WidgetRef ref, EntiteService service) async {
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

  Future<void> _noter(BuildContext context, WidgetRef ref, String cibleType, String cibleId, {String? serviceId}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogueNotation(
        titre: 'Noter le prestataire',
        cibleId: cibleId,
        cibleType: cibleType,
        serviceId: serviceId,
        onSuccess: () {
          ref.invalidate(serviceDetailProvider(id));
          ref.invalidate(avisServiceProvider(id));
        },
      ),
    );
    if (result == true) {
      ref.invalidate(serviceDetailProvider(id));
      ref.invalidate(avisServiceProvider(id));
      if (context.mounted) context.showSnackBar('Avis envoyé !');
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(id));
    final avisAsync = ref.watch(avisServiceProvider(id));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.utilisateur?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du service')),
      body: serviceAsync.when(
        data: (service) {
          final isOwner = currentUserId == service.utilisateurId;
          final utilisateurNom = (service.utilisateurNom ?? '').trim();
          final categorie = service.categorie ?? 'Sans catégorie';
          final description = service.description ?? '';
          final prixTexte = (service.prix?.toStringAsFixed(0) ?? '0');
          final distanceTexte = (service.distanceKm?.toStringAsFixed(1) ?? '0.0');
          final noteTexte = (service.noteMoyenne?.toStringAsFixed(1) ?? '0.0');

          // Compteur d'avis dynamique (basé sur la liste réelle)
          final nbAvisReels = avisAsync.when(
            data: (avis) => avis.length,
            loading: () => service.nbAvis ?? 0,
            error: (_, __) => service.nbAvis ?? 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: (service.photoUrl != null && service.photoUrl!.isNotEmpty)
                          ? NetworkImage(service.photoUrl!)
                          : null,
                      child: (service.photoUrl == null || service.photoUrl!.isEmpty)
                          ? (utilisateurNom.isNotEmpty ? Text(utilisateurNom[0]) : const Text('?'))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.titre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('par $utilisateurNom'),
                          Row(
                            children: [
                              EtoilesEvaluation(note: service.noteMoyenne, taille: 16),
                              const SizedBox(width: 4),
                              Text('$noteTexte ($nbAvisReels avis)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Description :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 12),
                Text('Catégorie : $categorie'),
                Text('Prix : $prixTexte Ar/h'),
                Text('Distance : $distanceTexte km'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _contacter(context, ref, service),
                  icon: const Icon(Icons.message),
                  label: const Text('Contacter'),
                ),
                const SizedBox(height: 12),
                if (!isOwner)
                  ElevatedButton.icon(
                    onPressed: () => _noter(context, ref, 'utilisateur', service.utilisateurId, serviceId: service.id),
                    icon: const Icon(Icons.star),
                    label: const Text('Noter ce prestataire'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  ),
                const SizedBox(height: 24),
                const Text('Avis sur ce service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                avisAsync.when(
                  data: (avis) => avis.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun avis pour ce service.'))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: avis.length,
                    itemBuilder: (ctx, i) {
                      final a = avis[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(a.auteurNom),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (star) => Icon(
                                    star < a.noteGlobale.round() ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.orange,
                                  )),
                                  const SizedBox(width: 8),
                                  Text('${a.noteGlobale.toStringAsFixed(1)}/5'),
                                ],
                              ),
                              if (a.commentaire != null && a.commentaire!.isNotEmpty) Text(a.commentaire!),
                              Text(_formatDate(a.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Erreur chargement avis : $err'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur : $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(serviceDetailProvider(id)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 0),
    );
  }
}