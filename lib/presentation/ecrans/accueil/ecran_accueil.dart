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

class EcranAccueil extends ConsumerStatefulWidget {
  const EcranAccueil({super.key});

  @override
  ConsumerState<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends ConsumerState<EcranAccueil> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'Bricolage',
    'Jardinage',
    'Transport',
    'Informatique',
    'Cours',
    'Garde / Soin',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProchesProvider);
    final demandesAsync = ref.watch(demandesProchesProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.utilisateur?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpNeighbor'),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profil/$userId'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(servicesProchesProvider);
          ref.invalidate(demandesProchesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec localisation (optionnel)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18),
                    const SizedBox(width: 4),
                    const Text('Antsahavola'),
                    const Spacer(),
                    Text('Bonjour, ${authState.utilisateur?.prenom ?? 'Visiteur'} 🐝'),
                  ],
                ),
              ),
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un service...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 12),
              // Chips de catégories
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Services à proximité
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Voisins disponibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              servicesAsync.when(
                data: (services) {
                  final filtered = _filterServices(services);
                  return Column(
                    children: filtered.map((s) => CarteService(service: s)).toList(),
                  );
                },
                loading: () => const IndicateurChargement(),
                error: (err, _) => WidgetErreur(message: err.toString()),
              ),
              const SizedBox(height: 16),
              // Demandes récentes
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Demandes récentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              demandesAsync.when(
                data: (demandes) {
                  final filtered = _filterDemandes(demandes);
                  return Column(
                    children: filtered.map((d) => CarteDemande(demande: d)).toList(),
                  );
                },
                loading: () => const IndicateurChargement(),
                error: (err, _) => WidgetErreur(message: err.toString()),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 0),
    );
  }

  List<EntiteService> _filterServices(List<EntiteService> services) {
    return services.where((s) {
      final matchesQuery = _searchQuery.isEmpty ||
          s.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Toutes' ||
          s.categorie == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<EntiteDemande> _filterDemandes(List<EntiteDemande> demandes) {
    return demandes.where((d) {
      return _searchQuery.isEmpty ||
          d.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
}