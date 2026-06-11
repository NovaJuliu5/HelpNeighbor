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

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la demande'),
        content: const Text('Voulez-vous vraiment supprimer cette demande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      final depot = getIt<DepotDemande>();
      final result = await depot.supprimerDemande(demande.id);
      result.fold(
            (echec) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(echec.message, style: const TextStyle(color: Colors.white)))),
            (_) {
          ref.invalidate(demandesProchesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demande supprimée avec succès')));
        },
      );
    }
  }

  void _modifier(BuildContext context) {
    context.push('/modifier-demande', extra: demande);
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
    final adresse = (demande.adresse?.isNotEmpty == true) ? demande.adresse! : 'Adresse non renseignée';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _voirProfil(context),
          behavior: HitTestBehavior.opaque,
          child: CircleAvatar(
            backgroundImage: (demande.photoUrl != null && demande.photoUrl!.isNotEmpty)
                ? NetworkImage(demande.photoUrl!)
                : null,
            child: (demande.photoUrl == null || demande.photoUrl!.isEmpty)
                ? Text(demande.utilisateurNom[0])
                : null,
          ),
        ),
        title: Text(demande.titre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(demande.utilisateurNom),
            Text(demande.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: Text(
                    adresse,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.flag_outlined, size: 20),
              onPressed: () => _signaler(context, ref),
              tooltip: 'Signaler',
            ),
            if (isOwner) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _modifier(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _supprimer(context, ref),
              ),
            ],
            Chip(label: Text(demande.statut)),
          ],
        ),
        onTap: () => context.push('/demande/${demande.id}'),
      ),
    );
  }
}