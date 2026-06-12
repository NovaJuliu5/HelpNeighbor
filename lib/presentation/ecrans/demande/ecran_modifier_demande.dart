import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_demande.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';

class EcranModifierDemande extends ConsumerStatefulWidget {
  final EntiteDemande demande;
  const EcranModifierDemande({super.key, required this.demande});

  @override
  ConsumerState<EcranModifierDemande> createState() => _EcranModifierDemandeState();
}

class _EcranModifierDemandeState extends ConsumerState<EcranModifierDemande> {
  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.demande.titre);
    _descriptionController = TextEditingController(text: widget.demande.description);
    _prixController = TextEditingController(text: widget.demande.prix.toString());
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la demande')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'TITRE'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'DESCRIPTION'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prixController,
              decoration: const InputDecoration(labelText: 'Prix (Ar)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _modifier,
              child: const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 0),
    );
  }

  Future<void> _modifier() async {
    if (_titreController.text.isEmpty || _descriptionController.text.isEmpty) {
      context.showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final data = {
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'prix': double.tryParse(_prixController.text) ?? 0.0,
    };
    final depot = getIt<DepotDemande>();
    final result = await depot.mettreAJourDemande(widget.demande.id, data);
    setState(() => _isLoading = false);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Demande modifiée avec succès !');
        ref.invalidate(demandesProchesProvider);
        context.pop();
      },
    );
  }
}