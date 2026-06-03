import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/fournisseur_accueil.dart';
import 'package:help_neighbor/presentation/widgets/cartes/carte_service.dart';
import 'package:help_neighbor/presentation/widgets/cartes/carte_demande.dart';
import 'package:help_neighbor/presentation/widgets/communs/indicateur_chargement.dart';
import 'package:help_neighbor/presentation/widgets/communs/widget_erreur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';

class EcranExplorer extends ConsumerStatefulWidget {
  const EcranExplorer({super.key});

  @override
  ConsumerState<EcranExplorer> createState() => _EcranExplorerState();
}

class _EcranExplorerState extends ConsumerState<EcranExplorer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryServices = 'Toutes';
  String _selectedCategoryDemandes = 'Toutes';
  bool _showServices = true;

  // Liste des catégories (commune aux services et demandes)
  final List<String> _categories = [
    'Toutes',
    'Bricolage',
    'Jardinage',
    'Transport',
    'Informatique',
    'Cours',
    'Garde / Soin',
  ];

  List<EntiteService> _filterServices(List<EntiteService> services) {
    return services.where((service) {
      final matchesQuery = _searchQuery.isEmpty ||
          service.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryServices == 'Toutes' ||
          service.categorie == _selectedCategoryServices;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<EntiteDemande> _filterDemandes(List<EntiteDemande> demandes) {
    // Pour les demandes, on filtre par titre/description et par catégorie
    // Note : la catégorie n'est pas encore disponible dans EntiteDemande,
    // on utilise une approximation (le titre ou la description contient la catégorie ?)
    // À améliorer plus tard si besoin.
    return demandes.where((demande) {
      final matchesQuery = _searchQuery.isEmpty ||
          demande.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          demande.description.toLowerCase().contains(_searchQuery.toLowerCase());
      // Pour les demandes, on n'a pas de champ catégorie dans EntiteDemande actuellement.
      // On peut soit ajouter ce champ, soit ignorer le filtre catégorie pour les demandes.
      // Ici on ignore le filtre (on retourne seulement matchesQuery).
      // Pour activer le filtrage, il faudrait étendre EntiteDemande avec un champ 'categorie'.
      return matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProchesProvider);
    final demandesAsync = ref.watch(demandesProchesProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.utilisateur?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profil/$userId'),
            ),
        ],
        bottom: PreferredSize(
          // Hauteur augmentée pour accueillir tous les éléments sans overflow
          preferredSize: const Size.fromHeight(160),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Sélecteur Services / Demandes avec icônes
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Services'),
                      icon: Icon(Icons.build),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Demandes'),
                      icon: Icon(Icons.help_outline),
                    ),
                  ],
                  selected: {_showServices},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _showServices = selection.first;
                      // Réinitialiser la recherche lors du changement d'onglet
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _showServices
                        ? 'Rechercher un service...'
                        : 'Rechercher une demande...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                // Filtre par catégorie (pour les deux modes)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _showServices
                          ? _selectedCategoryServices == cat
                          : _selectedCategoryDemandes == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (_showServices) {
                                _selectedCategoryServices = selected ? cat : 'Toutes';
                              } else {
                                _selectedCategoryDemandes = selected ? cat : 'Toutes';
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _showServices
          ? RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(servicesProchesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: servicesAsync.when(
          data: (services) {
            final filtered = _filterServices(services);
            if (filtered.isEmpty) {
              return const Center(child: Text('Aucun service trouvé'));
            }
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  CarteService(service: filtered[index]),
            );
          },
          loading: () => const IndicateurChargement(),
          error: (err, _) => WidgetErreur(message: err.toString()),
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(demandesProchesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: demandesAsync.when(
          data: (demandes) {
            final filtered = _filterDemandes(demandes);
            if (filtered.isEmpty) {
              return const Center(child: Text('Aucune demande trouvée'));
            }
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  CarteDemande(demande: filtered[index]),
            );
          },
          loading: () => const IndicateurChargement(),
          error: (err, _) => WidgetErreur(message: err.toString()),
        ),
      ),
      bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 1),
    );
  }
}