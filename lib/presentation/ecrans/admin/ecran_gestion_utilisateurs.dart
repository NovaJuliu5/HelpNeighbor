import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_admin.dart';
import 'package:help_neighbor/domaine/entites/entite_utilisateur_admin.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';

class EcranGestionUtilisateurs extends ConsumerStatefulWidget {
  const EcranGestionUtilisateurs({super.key});

  @override
  ConsumerState<EcranGestionUtilisateurs> createState() => _EcranGestionUtilisateursState();
}

class _EcranGestionUtilisateursState extends ConsumerState<EcranGestionUtilisateurs> {
  List<UtilisateurAdmin> _users = [];
  bool _isLoading = true;
  bool _isAdmin = false;       // true si l'utilisateur connecté est admin (pour le changement de rôle)
  bool _isAuthorized = false;  // true si admin ou moderateur (pour accéder à la liste et supprimer)

  @override
  void initState() {
    super.initState();
    _verifierRole();
  }

  Future<void> _verifierRole() async {
    final authState = ref.read(authProvider);
    final role = authState.utilisateur?.role;
    print('[GESTION] Rôle de l\'utilisateur connecté : $role');

    if (role == 'admin') {
      setState(() {
        _isAdmin = true;
        _isAuthorized = true;
      });
      await _chargerUtilisateurs();
    } else if (role == 'moderateur') {
      setState(() {
        _isAdmin = false;
        _isAuthorized = true;
      });
      await _chargerUtilisateurs();
    } else {
      print('[GESTION] Accès refusé, redirection vers accueil');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accès non autorisé. Vous devez être administrateur ou modérateur.')),
        );
        context.go('/accueil');
      }
    }
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() => _isLoading = true);
    final depot = getIt<DepotAdmin>();
    final result = await depot.listerUtilisateurs();
    result.fold(
          (echec) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(echec.message))),
          (users) => setState(() {
        _users = users;
        _isLoading = false;
      }),
    );
  }

  // Dialogue de sélection du rôle (réservé aux admins)
  Future<void> _changerRole(String userId) async {
    final nouveauRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Utilisateur'),
              onTap: () => Navigator.pop(ctx, 'user'),
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('Modérateur'),
              onTap: () => Navigator.pop(ctx, 'moderateur'),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administrateur'),
              onTap: () => Navigator.pop(ctx, 'admin'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ],
      ),
    );
    if (nouveauRole != null) {
      final depot = getIt<DepotAdmin>();
      final result = await depot.changerRole(userId, nouveauRole);
      result.fold(
            (echec) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(echec.message))),
            (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rôle mis à jour avec succès')),
          );
          _chargerUtilisateurs();
        },
      );
    }
  }

  // Suppression (accessible aux admins ET modérateurs, mais impossible sur un admin)
  Future<void> _supprimerUtilisateur(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Supprimer définitivement cet utilisateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    final depot = getIt<DepotAdmin>();
    final result = await depot.supprimerUtilisateur(userId);
    result.fold(
          (echec) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(echec.message))),
          (_) => _chargerUtilisateurs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des utilisateurs')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, index) {
          final u = _users[index];
          final targetIsAdmin = u.role == 'admin';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(child: Text(u.prenom?[0] ?? u.email[0])),
              title: Text('${u.prenom ?? ''} ${u.nom ?? ''}'.trim()),
              subtitle: Text(
                '${u.email}\nRôle: ${u.role} | Services: ${u.nbServices} | Demandes: ${u.nbDemandes}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'role') {
                    _changerRole(u.id);
                  }
                  if (value == 'delete') _supprimerUtilisateur(u.id);
                },
                itemBuilder: (ctx) {
                  final items = <PopupMenuEntry<String>>[];
                  // Option "Changer le rôle" : seulement si l'utilisateur connecté est admin
                  if (_isAdmin) {
                    items.add(
                      const PopupMenuItem(
                        value: 'role',
                        child: Text('Changer le rôle'),
                      ),
                    );
                  }
                  // Option "Supprimer" : si l'utilisateur connecté est autorisé (admin ou moderateur)
                  // ET que la cible n'est pas admin
                  if (_isAuthorized && !targetIsAdmin) {
                    items.add(
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    );
                  }
                  // Si aucun item, on ajoute un placeholder désactivé
                  if (items.isEmpty) {
                    items.add(
                      const PopupMenuItem(
                        enabled: false,
                        child: Text('Aucune action disponible'),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 4),
    );
  }
}