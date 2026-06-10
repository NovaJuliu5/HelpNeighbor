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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verifierRole();
  }

  Future<void> _verifierRole() async {
    final authState = ref.read(authProvider);
    final role = authState.utilisateur?.role;
    print('🔍 [ADMIN] Rôle de l\'utilisateur connecté : $role'); // ← AJOUT
    if (role != 'admin') {
      print('🚫 [ADMIN] Accès refusé, redirection vers accueil');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accès non autorisé. Vous devez être administrateur.')),
        );
        context.go('/accueil');
      }
      return;
    }
    print('✅ [ADMIN] Accès autorisé, chargement des utilisateurs');
    setState(() => _isAdmin = true);
    await _chargerUtilisateurs();
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

  Future<void> _changerRole(String userId, String nouveauRole) async {
    final depot = getIt<DepotAdmin>();
    final result = await depot.changerRole(userId, nouveauRole);
    result.fold(
          (echec) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(echec.message))),
          (_) => _chargerUtilisateurs(),
    );
  }

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
    if (!_isAdmin) {
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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(child: Text(u.prenom?[0] ?? u.email[0])),
              title: Text('${u.prenom ?? ''} ${u.nom ?? ''}'.trim()),
              subtitle: Text('${u.email}\nServices: ${u.nbServices} | Demandes: ${u.nbDemandes}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'role') {
                    _changerRole(u.id, u.role == 'admin' ? 'user' : 'admin');
                  }
                  if (value == 'delete') _supprimerUtilisateur(u.id);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'role',
                    child: Text(u.role == 'admin' ? 'Rétrograder en utilisateur' : 'Promouvoir administrateur'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 4),
    );
  }
}