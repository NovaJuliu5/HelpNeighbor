import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/domaine/entites/entite_offre.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/widgets/communs/dialogue_notation.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_demande.dart';
import 'package:help_neighbor/donnees/depots/depot_offre.dart';
import 'package:help_neighbor/donnees/depots/depot_conversation.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';

class EcranDetailDemande extends ConsumerStatefulWidget {
  final String id;
  const EcranDetailDemande({super.key, required this.id});

  @override
  ConsumerState<EcranDetailDemande> createState() => _EcranDetailDemandeState();
}

class _EcranDetailDemandeState extends ConsumerState<EcranDetailDemande> {
  EntiteDemande? _demande;
  List<EntiteOffre> _offres = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    final depotDemande = getIt<DepotDemande>();
    final demandeResult = await depotDemande.obtenirDemandeParId(widget.id);
    demandeResult.fold(
          (echec) => setState(() {
        _error = echec.message;
        _isLoading = false;
      }),
          (demande) => setState(() {
        _demande = demande;
        _isLoading = false;
      }),
    );

    final authState = ref.read(authProvider);
    if (authState.utilisateur?.id == _demande?.utilisateurId && _demande != null) {
      final depotOffre = getIt<DepotOffre>();
      final offresResult = await depotOffre.getOffresPourDemande(widget.id);
      offresResult.fold(
            (echec) => setState(() => _error = echec.message),
            (offres) => setState(() => _offres = offres),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _supprimer() async {
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
      final result = await depot.supprimerDemande(widget.id);
      result.fold(
            (echec) => context.showSnackBar(echec.message, isError: true),
            (_) {
          ref.invalidate(demandesProchesProvider);
          context.showSnackBar('Demande supprimée avec succès');
          context.pop();
        },
      );
    }
  }

  void _modifier() {
    if (_demande != null) {
      context.push('/modifier-demande', extra: _demande);
    }
  }

  Future<void> _repondreOffre(String offreId, String statut) async {
    final depot = getIt<DepotOffre>();
    final result = await depot.repondreOffre(offreId, statut);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar(statut == 'acceptee' ? 'Offre acceptée' : 'Offre refusée');
        _chargerDonnees();
      },
    );
  }

  Future<void> _contacterDemandeur() async {
    if (_demande == null) return;
    final depotConv = getIt<DepotConversation>();
    final result = await depotConv.creerConversation(
      _demande!.utilisateurId,
      demandeId: widget.id,
    );
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (convId) => context.push('/discussion/$convId', extra: {'autreNom': _demande!.utilisateurNom}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.utilisateur?.id == _demande?.utilisateurId;
    final isOpen = _demande?.statut == 'ouverte';
    EntiteOffre? offreAcceptee;
    for (var offre in _offres) {
      if (offre.statut == 'acceptee') {
        offreAcceptee = offre;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la demande'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _modifier,
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _supprimer,
              tooltip: 'Supprimer',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Erreur: $_error'))
          : RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_demande!.titre,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_demande!.description),
              const SizedBox(height: 8),
              Text('Statut: ${_demande!.statut}'),
              const SizedBox(height: 8),
              Text('Prix : ${_demande!.prix} Ar'),
              const SizedBox(height: 16),
              if (!isOwner && isOpen) ...[
                _FormulaireOffre(demandeId: widget.id, onOffreEnvoyee: _chargerDonnees),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _contacterDemandeur,
                  child: const Text('Contacter le demandeur'),
                ),
              ],
              if (isOwner && _offres.isNotEmpty) ...[
                const Text('Offres reçues:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ..._offres.map((offre) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(offre.prestataireNom),
                    subtitle: Text(offre.message),
                    trailing: offre.statut == 'en_attente'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _repondreOffre(offre.id, 'acceptee'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _repondreOffre(offre.id, 'refusee'),
                        ),
                      ],
                    )
                        : Chip(label: Text(offre.statut)),
                  ),
                )),
              ],
              if (isOwner && offreAcceptee != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => DialogueNotation(
                        cibleId: offreAcceptee!.prestataireId,
                        cibleType: 'utilisateur',
                        demandeId: widget.id,
                      ),
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Noter ce prestataire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 3),
    );
  }
}

// Formulaire d'offre inchangé
class _FormulaireOffre extends ConsumerStatefulWidget {
  final String demandeId;
  final VoidCallback onOffreEnvoyee;
  const _FormulaireOffre({required this.demandeId, required this.onOffreEnvoyee});

  @override
  ConsumerState<_FormulaireOffre> createState() => _FormulaireOffreState();
}

class _FormulaireOffreState extends ConsumerState<_FormulaireOffre> {
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Faire une offre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Message...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _envoyerOffre,
          child: const Text('Envoyer l\'offre'),
        ),
      ],
    );
  }

  Future<void> _envoyerOffre() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final authState = ref.read(authProvider);
    final prestataireId = authState.utilisateur?.id;
    if (prestataireId == null) {
      context.showSnackBar('Vous devez être connecté', isError: true);
      setState(() => _isLoading = false);
      return;
    }
    final depot = getIt<DepotOffre>();
    final result = await depot.creerOffre({
      'demande_id': widget.demandeId,
      'prestataire_id': prestataireId,
      'message': _messageController.text,
    });
    setState(() => _isLoading = false);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Offre envoyée !');
        _messageController.clear();
        widget.onOffreEnvoyee();
      },
    );
  }
}