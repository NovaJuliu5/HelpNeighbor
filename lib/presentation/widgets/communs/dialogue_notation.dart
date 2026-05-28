import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_avis.dart';
import 'package:help_neighbor/domaine/entites/entite_avis.dart';

class DialogueNotation extends ConsumerStatefulWidget {
  final String cibleId;
  final String cibleType;
  final String? serviceId;
  final String? demandeId;
  final VoidCallback? onSuccess;

  const DialogueNotation({
    super.key,
    required this.cibleId,
    required this.cibleType,
    this.serviceId,
    this.demandeId,
    this.onSuccess,
  });

  @override
  ConsumerState<DialogueNotation> createState() => _DialogueNotationState();
}

class _DialogueNotationState extends ConsumerState<DialogueNotation> {
  double _noteGlobale = 0;
  final TextEditingController _commentaireController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _existingAvisId;

  @override
  void initState() {
    super.initState();
    _chargerAvisExistant();
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _chargerAvisExistant() async {
    final depot = getIt<DepotAvis>();
    final result = await depot.getAvisCurrent(widget.cibleId, serviceId: widget.serviceId);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (avis) {
        if (avis != null) {
          setState(() {
            _existingAvisId = avis.id;
            _noteGlobale = avis.noteGlobale;
            _commentaireController.text = avis.commentaire ?? '';
          });
        }
        _isLoading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
      );
    }
    return AlertDialog(
      title: Text(_existingAvisId == null ? 'Noter ce prestataire' : 'Modifier votre avis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Note globale (1 à 5) :'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _noteGlobale ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _noteGlobale = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentaireController,
            decoration: const InputDecoration(
              hintText: 'Votre commentaire (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _noteGlobale == 0 ? null : _envoyerAvis,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text('Envoyer'),
        ),
      ],
    );
  }

  Future<void> _envoyerAvis() async {
    setState(() => _isSaving = true);
    final depot = getIt<DepotAvis>();
    final data = {
      'cible_id': widget.cibleId,
      'cible_type': widget.cibleType,
      'service_id': widget.serviceId,
      'demande_id': widget.demandeId,
      'commentaire': _commentaireController.text,
      'note_globale': _noteGlobale,
    };
    late final result;
    if (_existingAvisId != null) {
      result = await depot.modifierAvis(_existingAvisId!, data);
    } else {
      result = await depot.creerAvis(data);
    }
    setState(() => _isSaving = false);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar(_existingAvisId == null ? 'Merci pour votre avis !' : 'Avis modifié !');
        widget.onSuccess?.call();
        Navigator.pop(context);
      },
    );
  }
}