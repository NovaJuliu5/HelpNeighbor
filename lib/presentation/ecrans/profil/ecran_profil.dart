import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/domaine/entites/entite_avis.dart';
import 'package:help_neighbor/donnees/depots/depot_authentification.dart';
import 'package:help_neighbor/donnees/depots/depot_avis.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_utilisateur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/widgets/communs/dialogue_notation.dart';

final avisUtilisateurProvider = FutureProvider.family<List<EntiteAvis>, String>((ref, userId) async {
  final depot = getIt<DepotAvis>();
  final result = await depot.listerAvis(cibleId: userId, cibleType: 'utilisateur');
  return result.fold((echec) => [], (avis) => avis);
});

class EcranProfil extends ConsumerWidget {
  final String userId;
  const EcranProfil({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Si l'utilisateur n'est pas encore chargé, afficher un indicateur
    if (authState.utilisateur == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4),
      );
    }

    final isOwnProfile = authState.utilisateur?.id == userId;
    final isAdmin = authState.utilisateur?.role == 'admin';
    final isModerateur = authState.utilisateur?.role == 'moderateur';
    final profilAsync = ref.watch(profilUtilisateurProvider(userId));
    final avisAsync = ref.watch(avisUtilisateurProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/profil/modifier'),
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _deconnexion(context, ref),
            ),
        ],
      ),
      body: profilAsync.when(
        data: (utilisateur) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (utilisateur.photoUrl != null && utilisateur.photoUrl!.isNotEmpty)
                        ? NetworkImage(utilisateur.photoUrl!)
                        : null,
                    child: (utilisateur.photoUrl == null || utilisateur.photoUrl!.isEmpty)
                        ? Text(utilisateur.prenom?[0] ?? 'U')
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${utilisateur.prenom} ${utilisateur.nom}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(utilisateur.email),
                        if (utilisateur.telephone != null)
                          Text('Tél: ${utilisateur.telephone}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bio
              const Text('À propos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(utilisateur.bio ?? 'Aucune bio'),
              const SizedBox(height: 24),

              // Statistiques
              const Text('Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard('Services', utilisateur.nbServices ?? 0),
                  _StatCard('Demandes', utilisateur.nbDemandes ?? 0),
                  _StatCard('Note', utilisateur.noteMoyenne.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),

              // Bouton Noter (si ce n'est pas son propre profil)
              if (!isOwnProfile) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.star_rate),
                  label: const Text('Noter cet utilisateur'),
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => DialogueNotation(
                        titre: 'Noter ${utilisateur.prenom} ${utilisateur.nom}',
                        cibleId: userId,
                        cibleType: 'utilisateur',
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(profilUtilisateurProvider(userId));
                      ref.invalidate(avisUtilisateurProvider(userId));
                      if (context.mounted) {
                        context.showSnackBar('Avis envoyé, merci !');
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Liste des avis
              const Text('Avis des membres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              avisAsync.when(
                data: (avis) => avis.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun avis pour le moment.'),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: avis.length,
                  itemBuilder: (ctx, i) {
                    final a = avis[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.person, size: 32),
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
                            if (a.commentaire != null && a.commentaire!.isNotEmpty)
                              Text(a.commentaire!),
                            Text(_formatDate(a.createdAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Erreur chargement avis: $err'),
              ),
              const SizedBox(height: 24),

              // Section administration (visible pour admin OU moderateur sur son propre profil)
              if (isOwnProfile && (isAdmin || isModerateur)) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isAdmin ? Colors.blue.shade50 : Colors.green.shade50,
                  child: ListTile(
                    leading: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.shield,
                      color: isAdmin ? Colors.blue : Colors.green,
                    ),
                    title: Text(
                      isAdmin ? 'Gestion des utilisateurs' : 'Modération - Utilisateurs',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isAdmin
                          ? 'Accéder à l’espace d’administration'
                          : 'Voir et gérer les utilisateurs (modérateur)',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/admin/utilisateurs'),
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 4),
    );
  }

  Future<void> _deconnexion(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      final depot = getIt<DepotAuthentification>();
      await depot.deconnexion();

      // Invalider l'état d'authentification pour que les widgets réagissent
      ref.invalidate(authProvider);

      // ❌ NE PAS invalider profilUtilisateurProvider(userId)
      // Cela éviterait de relancer une requête après suppression du token

      // Rediriger vers l'écran de connexion
      context.go('/connexion');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final dynamic value;
  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }
}