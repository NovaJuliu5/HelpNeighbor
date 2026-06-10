import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_authentification.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_utilisateur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';

class EcranProfil extends ConsumerWidget {
  final String userId;
  const EcranProfil({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwnProfile = authState.utilisateur?.id == userId;
    final isAdmin = authState.utilisateur?.role == 'admin';
    // Utilisation du family provider avec l'ID passé en paramètre
    final profilAsync = ref.watch(profilUtilisateurProvider(userId));

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
              const Text('À propos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(utilisateur.bio ?? 'Aucune bio'),
              const SizedBox(height: 24),
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
              // 🔐 Section Administration (visible uniquement pour son propre profil admin)
              if (isOwnProfile && isAdmin) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                    title: const Text('Gestion des utilisateurs', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Accéder à l’espace d’administration'),
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
      bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4),
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
      ref.invalidate(authProvider);
      ref.invalidate(profilUtilisateurProvider(userId));
      context.go('/connexion');
    }
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