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
    return demandes.where((demande) {
      final matchesQuery = _searchQuery.isEmpty ||
          demande.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          demande.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesQuery;
    }).toList();
  }

  Future<void> _refresh() async {
    if (_showServices) {
      await ref.refresh(servicesProchesProvider.future);
    } else {
      await ref.refresh(demandesProchesProvider.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProchesProvider);
    final demandesAsync = ref.watch(demandesProchesProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.utilisateur?.id;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: primaryColor,
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profil/$userId'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(170),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // SegmentedButton personnalisé (vert)
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
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.selected)) {
                          return primaryColor;
                        }
                        return Colors.grey.shade100;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return primaryColor;
                      },
                    ),
                    side: WidgetStateProperty.resolveWith<BorderSide>(
                          (states) {
                        if (states.contains(WidgetState.selected)) {
                          return BorderSide(color: primaryColor, width: 2);
                        }
                        return const BorderSide(color: Colors.transparent);
                      },
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _showServices
                        ? 'Rechercher un service...'
                        : 'Rechercher une demande...',
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: primaryColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                // Filtres par catégorie (chips)
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
                          selectedColor: primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.white,
                          side: isSelected
                              ? BorderSide(color: primaryColor, width: 2)
                              : BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        onRefresh: _refresh,
        color: primaryColor,
        child: servicesAsync.when(
          data: (services) {
            final filtered = _filterServices(services);
            if (filtered.isEmpty) {
              return const Center(child: Text('Aucun service trouvé'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
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
        onRefresh: _refresh,
        color: primaryColor,
        child: demandesAsync.when(
          data: (demandes) {
            final filtered = _filterDemandes(demandes);
            if (filtered.isEmpty) {
              return const Center(child: Text('Aucune demande trouvée'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  CarteDemande(demande: filtered[index]),
            );
          },
          loading: () => const IndicateurChargement(),
          error: (err, _) => WidgetErreur(message: err.toString()),
        ),
      ),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 1),
    );
  }
}