import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_admin.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';

class EcranSignalements extends ConsumerStatefulWidget {
  const EcranSignalements({super.key});

  @override
  ConsumerState<EcranSignalements> createState() => _EcranSignalementsState();
}

class _EcranSignalementsState extends ConsumerState<EcranSignalements> {
  List<dynamic> _signalements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final depot = getIt<DepotAdmin>();
    final result = await depot.listerSignalements();
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (data) => setState(() {
        _signalements = data;
        _loading = false;
      }),
    );
  }

  Future<void> _supprimer(String type, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer définitivement ce $type ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    final depot = getIt<DepotAdmin>();
    final result = await depot.supprimerContenu(type, id);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Contenu supprimé');
        _charger();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signalements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _signalements.isEmpty
          ? const Center(child: Text('Aucun signalement'))
          : ListView.builder(
        itemCount: _signalements.length,
        itemBuilder: (ctx, i) {
          final s = _signalements[i];
          final type = s['cible_type'];
          final id = s['cible_id'];
          final total = s['total'];
          final motifs = s['motifs'] ?? 'Non spécifié';
          final dernier = s['dernier_signalement'];

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type: $type',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('ID: $id'),
                  const SizedBox(height: 4),
                  Text('Signalements: $total'),
                  Text('Motifs: $motifs'),
                  Text('Dernier signalement: $dernier'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('Voir'),
                        onPressed: () {
                          // Redirection selon le type
                          if (type == 'service') {
                            context.push('/service/$id');
                          } else if (type == 'demande') {
                            context.push('/demande/$id');
                          } else if (type == 'avis') {
                            // Pour un avis, on peut rediriger vers le profil de l'auteur ou la page du service lié
                            context.showSnackBar('Redirection vers l\'avis non implémentée', isError: true);
                          } else {
                            context.showSnackBar('Type inconnu', isError: true);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Supprimer'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => _supprimer(type, id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}