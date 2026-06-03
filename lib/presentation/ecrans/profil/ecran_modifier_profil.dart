import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_utilisateur.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_utilisateur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';

class EcranModifierProfil extends ConsumerStatefulWidget {
  const EcranModifierProfil({super.key});

  @override
  ConsumerState<EcranModifierProfil> createState() => _EcranModifierProfilState();
}

class _EcranModifierProfilState extends ConsumerState<EcranModifierProfil> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final authState = ref.read(authProvider);
    final userId = authState.utilisateur?.id;
    if (userId == null) {
      context.showSnackBar('Utilisateur non connecté', isError: true);
      return;
    }
    _userId = userId;
    await _chargerProfil(userId);
  }

  Future<void> _chargerProfil(String userId) async {
    final utilisateur = await ref.read(profilUtilisateurProvider(userId).future);
    _nomController.text = utilisateur.nom ?? '';
    _prenomController.text = utilisateur.prenom ?? '';
    _bioController.text = utilisateur.bio ?? '';
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sauvegarder,
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4), // retiré const
    );
  }

  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);
    final data = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'bio': _bioController.text,
    };
    final depot = getIt<DepotUtilisateur>();
    final result = await depot.mettreAJourProfil(data);
    setState(() => _isSaving = false);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Profil mis à jour !');
        if (_userId != null) {
          ref.invalidate(profilUtilisateurProvider(_userId!));
        }
        Navigator.pop(context);
      },
    );
  }
}