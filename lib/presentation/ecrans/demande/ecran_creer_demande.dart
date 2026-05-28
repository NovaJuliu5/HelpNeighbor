import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/domaine/cas_utilisation/demande/creer_demande_usecase.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';

class EcranCreerDemande extends ConsumerStatefulWidget {
  const EcranCreerDemande({super.key});

  @override
  ConsumerState<EcranCreerDemande> createState() => _EcranCreerDemandeState();
}

class _EcranCreerDemandeState extends ConsumerState<EcranCreerDemande> {
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _categorieNom = 'Bricolage';
  String _urgence = 'Pas pressé';
  String _remuneration = 'Gratuit / Échange';
  bool _isLoading = false;

  final List<String> _categories = [
    'Bricolage',
    'Jardinage',
    'Transport',
    'Informatique',
    'Cours',
    'Garde / Soin',
  ];

  final List<String> _urgences = ['Pas pressé', 'Cette semaine', 'Urgent !'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une demande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'TITRE', hintText: 'ex: Aide pour réparer une fuite d\'eau'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'DESCRIPTION', hintText: 'Décrivez votre besoin en détail...'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categorieNom,
              items: _categories.map((nom) => DropdownMenuItem(value: nom, child: Text(nom))).toList(),
              onChanged: (val) => setState(() => _categorieNom = val!),
              decoration: const InputDecoration(labelText: 'CATÉGORIE'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _urgence,
              items: _urgences.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (val) => setState(() => _urgence = val!),
              decoration: const InputDecoration(labelText: 'URGENCE'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _remuneration,
              items: ['Gratuit / Échange', 'Montant en Ar'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _remuneration = val!),
              decoration: const InputDecoration(labelText: 'RÉMUNÉRATION'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _publier,
              child: const Text('Publier ma demande'),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/creer-service'),
              child: const Text('Vous voulez proposer un service ?'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 2),
    );
  }

  Future<void> _publier() async {
    if (_titreController.text.isEmpty || _descriptionController.text.isEmpty) {
      context.showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final data = {
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'categorie_nom': _categorieNom,
    };
    final useCase = CreerDemandeUseCase(getIt());
    final result = await useCase.executer(data);
    result.fold(
          (echec) {
        setState(() => _isLoading = false);
        context.showSnackBar(echec.message, isError: true);
      },
          (_) {
        setState(() => _isLoading = false);
        context.showSnackBar('Demande publiée avec succès !');
        ref.invalidate(demandesProchesProvider);
        context.pop();
      },
    );
  }
}