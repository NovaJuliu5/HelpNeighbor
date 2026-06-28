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

  Future<void> _contacterPrestataire(String prestataireId) async {
    final offre = _offres.firstWhere((o) => o.prestataireId == prestataireId);
    final depotConv = getIt<DepotConversation>();
    final result = await depotConv.creerConversation(
      prestataireId,
      demandeId: widget.id,
    );
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (convId) => context.push('/discussion/$convId', extra: {'autreNom': offre.prestataireNom}),
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
    final primaryColor = Theme.of(context).primaryColor;

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
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
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
        color: primaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Carte principale ---
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: (_demande!.photoUrl != null &&
                                _demande!.photoUrl!.isNotEmpty)
                                ? NetworkImage(_demande!.photoUrl!)
                                : null,
                            child: (_demande!.photoUrl == null ||
                                _demande!.photoUrl!.isEmpty)
                                ? Text(_demande!.utilisateurNom?.substring(0, 1) ?? 'U',
                                style: const TextStyle(fontSize: 24))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _demande!.titre,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'par ${_demande!.utilisateurNom ?? 'Inconnu'}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        _demande!.description,
                        style: const TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                          icon: Icons.label, label: 'Statut', value: _demande!.statut),
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.attach_money,
                          label: 'Prix',
                          value: '${_demande!.prix} Ar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Actions principales ---
              if (!isOwner && isOpen) ...[
                // Formulaire d'offre
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _FormulaireOffre(
                      demandeId: widget.id,
                      onOffreEnvoyee: _chargerDonnees,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _contacterDemandeur,
                  icon: const Icon(Icons.message),
                  label: const Text('Contacter le demandeur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- Offres reçues (propriétaire uniquement) ---
              if (isOwner && _offres.isNotEmpty) ...[
                const Text(
                  'Offres reçues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _offres.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final offre = _offres[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.person, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offre.prestataireNom,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    offre.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.message),
                              color: primaryColor,
                              onPressed: () =>
                                  _contacterPrestataire(offre.prestataireId),
                              tooltip: 'Contacter',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // --- Noter le prestataire (si offre acceptée) ---
              if (isOwner && offreAcceptee != null) ...[
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
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 3),
    );
  }
}

// Formulaire d'offre amélioré (utilisé dans la carte)
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
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faire une offre',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Votre message pour le demandeur...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: _envoyerOffre,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Envoyer l\'offre'),
        ),
      ],
    );
  }

  Future<void> _envoyerOffre() async {
    if (_messageController.text.trim().isEmpty) {
      context.showSnackBar('Veuillez saisir un message', isError: true);
      return;
    }
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

// Widget utilitaire pour les lignes d'information (comme dans EcranDetailService)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}