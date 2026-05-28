import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/domaine/cas_utilisation/service/creer_service_usecase.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';
import 'package:help_neighbor/donnees/depots/depot_service.dart';

class EcranCreerService extends ConsumerStatefulWidget {
  const EcranCreerService({super.key});

  @override
  ConsumerState<EcranCreerService> createState() => _EcranCreerServiceState();
}

class _EcranCreerServiceState extends ConsumerState<EcranCreerService> {
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  String _categorieId = '';
  bool _disponible = true;
  bool _isLoading = false;

  // Liste des catégories (devrait venir du backend, mais pour l'instant statique)
  final List<Map<String, String>> _categories = [];

  @override
  void initState() {
    super.initState();
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    // Idéalement, créer un endpoint GET /categories dans le backend
    // Pour l'instant, on utilise une liste statique basée sur vos données existantes
    setState(() {
      _categories.addAll([
        {'id': '93d4b51d-1fd4-4976-8e58-6d7ed0c10a91', 'nom': 'Bricolage'},
        {'id': '026a6231-ca06-4dc0-a9a7-23f0822efd1a', 'nom': 'Jardinage'},
        {'id': 'a172e91b-600c-4341-929b-cd81a707dcdc', 'nom': 'Transport'},
        {'id': 'ee9765f2-666a-4e08-b34a-03fed0735f6e', 'nom': 'Informatique'},
        {'id': '8a6733d0-ffe2-4cd2-86bd-928f55553e23', 'nom': 'Cours particulier'},
        {'id': 'e7b5512b-7676-47c1-a46b-9d08be6002d2', 'nom': 'Garde enfant'},
      ]);
      if (_categories.isNotEmpty) _categorieId = _categories.first['id']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre du service',
                hintText: 'ex: Jardinage à domicile',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre service en détail...',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categorieId.isNotEmpty ? _categorieId : null,
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat['id'],
                  child: Text(cat['nom']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _categorieId = value!),
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prixController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix (Ar/h)',
                hintText: '5000',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Service disponible'),
              value: _disponible,
              onChanged: (value) => setState(() => _disponible = value),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _publier,
              child: const Text('Publier mon service'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 2), // onglet Publier
    );
  }

  Future<void> _publier() async {
    if (_titreController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _categorieId.isEmpty) {
      context.showSnackBar('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    final prix = double.tryParse(_prixController.text);
    if (prix == null || prix <= 0) {
      context.showSnackBar('Veuillez entrer un prix valide (supérieur à 0)', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'categorie_id': _categorieId,
      'prix': prix,
      'disponible': _disponible,
    };

    final useCase = CreerServiceUseCase(getIt());
    final result = await useCase.executer(data);

    setState(() => _isLoading = false);

    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Service publié avec succès !');
        // Rafraîchir les services dans l'accueil et l'explorateur
        ref.invalidate(servicesProchesProvider);
        context.go('/accueil');
      },
    );
  }
}