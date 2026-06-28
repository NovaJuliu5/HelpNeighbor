import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_demande.dart';
import 'package:help_neighbor/donnees/depots/depot_signalement.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';

class CarteDemande extends ConsumerWidget {
  final EntiteDemande demande;
  const CarteDemande({super.key, required this.demande});

  void _voirProfil(BuildContext context) {
    print("Navigation vers le profil de : ${demande.utilisateurId}");
    context.push('/profil/${demande.utilisateurId}');
  }

  Future<void> _changerStatut(BuildContext context, WidgetRef ref) async {
    final nouveauStatut = demande.statut == 'ouverte' ? 'fermee' : 'ouverte';
    final depot = getIt<DepotDemande>();
    final result = await depot.changerStatutDemande(demande.id, nouveauStatut);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar(nouveauStatut == 'ouverte' ? 'Demande ouverte' : 'Demande fermée');
        ref.invalidate(demandesProchesProvider);
      },
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
      cibleType: 'demande',
      cibleId: demande.id,
      motif: motif,
    );
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (msg) => context.showSnackBar(msg),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.utilisateur?.id == demande.utilisateurId;
    final primaryColor = Theme.of(context).primaryColor;
    final adresse = (demande.adresse?.isNotEmpty == true) ? demande.adresse! : 'Adresse non renseignée';
    final estOuverte = demande.statut == 'ouverte';

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
                    backgroundImage: (demande.photoUrl != null && demande.photoUrl!.isNotEmpty)
                        ? NetworkImage(demande.photoUrl!)
                        : null,
                    child: (demande.photoUrl == null || demande.photoUrl!.isEmpty)
                        ? Text(demande.utilisateurNom.isNotEmpty ? demande.utilisateurNom[0] : '?',
                        style: const TextStyle(fontSize: 20))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Informations de la demande
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande.titre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'par ${demande.utilisateurNom}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      // Statut de la demande (avec indicateur coloré)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: estOuverte ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              demande.statut,
                              style: TextStyle(
                                color: estOuverte ? Colors.green.shade800 : Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                // Boutons d'action (signaler, changer statut)
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
                    if (isOwner)
                      IconButton(
                        icon: Icon(
                          estOuverte ? Icons.lock_open : Icons.lock,
                          size: 22,
                        ),
                        color: estOuverte ? Colors.green : Colors.red,
                        onPressed: () => _changerStatut(context, ref),
                        tooltip: estOuverte ? 'Fermer la demande' : 'Ouvrir la demande',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description (2 lignes max)
            Text(
              demande.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Ligne des détails : prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${demande.prix} Ar',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                // Bouton "Voir détail" (discret)
                TextButton.icon(
                  onPressed: () => context.push('/demande/${demande.id}'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Voir'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}