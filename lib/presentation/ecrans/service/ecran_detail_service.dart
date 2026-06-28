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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du service'),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: serviceAsync.when(
        data: (service) {
          final isOwner = currentUserId == service.utilisateurId;
          final utilisateurNom = (service.utilisateurNom ?? '').trim();
          final categorie = service.categorie ?? 'Sans catégorie';
          final description = service.description ?? '';
          final prixTexte = (service.prix?.toStringAsFixed(0) ?? '0');
          final noteTexte = (service.noteMoyenne?.toStringAsFixed(1) ?? '0.0');

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
                // --- Carte d'identité du service ---
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
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
                                  ? (utilisateurNom.isNotEmpty
                                  ? Text(utilisateurNom[0], style: const TextStyle(fontSize: 24))
                                  : const Text('?'))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.titre,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'par $utilisateurNom',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      EtoilesEvaluation(note: service.noteMoyenne, taille: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$noteTexte ($nbAvisReels avis)',
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(description, style: const TextStyle(height: 1.4)),
                        const SizedBox(height: 16),
                        // Informations en lignes
                        _InfoRow(icon: Icons.category, label: 'Catégorie', value: categorie),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.attach_money, label: 'Prix', value: '$prixTexte Ar'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Boutons d'action ---
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contacter(context, ref, service),
                        icon: const Icon(Icons.message),
                        label: const Text('Contacter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isOwner)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _noter(context, ref, 'utilisateur', service.utilisateurId,
                              serviceId: service.id),
                          icon: const Icon(Icons.star),
                          label: const Text('Noter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Avis ---
                const Text(
                  'Avis sur ce service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                avisAsync.when(
                  data: (avis) => avis.isEmpty
                      ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Aucun avis pour ce service.'),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: avis.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final a = avis[i];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    a.auteurNom,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(a.createdAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ...List.generate(5, (star) => Icon(
                                    star < a.noteGlobale.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.orange,
                                  )),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${a.noteGlobale.toStringAsFixed(1)}/5',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              if (a.commentaire != null && a.commentaire!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(a.commentaire!),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Erreur chargement des avis: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
              Text('Erreur: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(serviceDetailProvider(id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
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

// Widget utilitaire pour afficher une ligne d'information avec icône
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}