import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_utilisateur.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/depots/depot_utilisateur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';

class EcranModifierProfil extends ConsumerStatefulWidget {
  const EcranModifierProfil({super.key});

  @override
  ConsumerState<EcranModifierProfil> createState() => _EcranModifierProfilState();
}

class _EcranModifierProfilState extends ConsumerState<EcranModifierProfil> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _bioController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _bioController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }

  Future<void> _loadUserId() async {
    final authState = ref.read(authProvider);
    final userId = authState.utilisateur?.id;

    print('🔍 _loadUserId: userId = $userId');

    if (userId == null) {
      print('❌ Aucun utilisateur connecté');
      _redirectToLogin(message: 'Utilisateur non connecté');
      return;
    }

    if (userId == "modifier" || !_isValidUuid(userId)) {
      print('❌ ID invalide détecté : $userId → déconnexion et redirection');
      ref.read(authProvider.notifier).deconnexion();
      _redirectToLogin(message: 'Session invalide, veuillez vous reconnecter.');
      return;
    }

    print('✅ ID utilisateur valide : $userId');
    _userId = userId;
    await _chargerProfil(userId);
  }

  void _redirectToLogin({required String message}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.showSnackBar(message, isError: true);
        context.go('/connexion');
      }
    });
  }

  Future<void> _chargerProfil(String userId) async {
    try {
      final utilisateur = await ref.read(profilUtilisateurProvider(userId).future);
      _nomController.text = utilisateur.nom ?? '';
      _prenomController.text = utilisateur.prenom ?? '';
      _bioController.text = utilisateur.bio ?? '';
      _adresseController.text = utilisateur.adresse ?? '';
      _villeController.text = utilisateur.ville ?? '';
      _codePostalController.text = utilisateur.codePostal ?? '';
      _paysController.text = utilisateur.pays ?? 'Madagascar';
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Exception dans _chargerProfil: $e');
      _redirectToLogin(message: 'Erreur chargement profil : veuillez vous reconnecter.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom')),
              const SizedBox(height: 12),
              TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
              const SizedBox(height: 12),
              TextField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse')),
              const SizedBox(height: 12),
              TextField(controller: _villeController, decoration: const InputDecoration(labelText: 'Ville')),
              const SizedBox(height: 12),
              TextField(controller: _codePostalController, decoration: const InputDecoration(labelText: 'Code postal')),
              const SizedBox(height: 12),
              TextField(controller: _paysController, decoration: const InputDecoration(labelText: 'Pays')),
              const SizedBox(height: 24),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _sauvegarder, child: const Text('Sauvegarder')),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarreNavigationBasPersonnalisee(selectedIndex: 4),
    );
  }

  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);
    final data = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'bio': _bioController.text,
      'adresse': _adresseController.text,
      'ville': _villeController.text,
      'code_postal': _codePostalController.text,
      'pays': _paysController.text,
    };
    final depot = getIt<DepotUtilisateur>();
    final result = await depot.mettreAJourProfil(data);
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.fold(
          (echec) => context.showSnackBar(echec.message, isError: true),
          (_) {
        context.showSnackBar('Profil mis à jour !');
        if (_userId != null) ref.invalidate(profilUtilisateurProvider(_userId!));
        Navigator.pop(context);
      },
    );
  }
}