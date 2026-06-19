import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/presentation/widgets/communs/bouton_personnalise.dart';

class EcranInscription extends ConsumerStatefulWidget {
  const EcranInscription({super.key});

  @override
  ConsumerState<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends ConsumerState<EcranInscription> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _navigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  // Validateur pour le Nom : 1-20 caractères, lettres et espaces
  String? _validerNom(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    if (value.length > 20) return 'Maximum 20 caractères';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Lettres et espaces uniquement';
    }
    return null;
  }

  // Validateur pour le Prénom : 1-32 caractères, lettres et espaces
  String? _validerPrenom(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    if (value.length > 32) return 'Maximum 32 caractères';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Lettres et espaces uniquement';
    }
    return null;
  }

  // Validateur pour le Mot de passe : exactement 6 caractères (tout caractère autorisé)
  String? _validerMotDePasse(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est requis';
    if (value.length != 6) return 'Doit contenir exactement 6 caractères';
    return null;
  }

  // Méthode d'inscription avec validation du formulaire
  Future<void> _inscrire() async {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).inscription(
        _emailController.text,
        _passwordController.text,
        _nomController.text,
        _prenomController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (next.erreur != null) {
        context.showSnackBar(next.erreur!.message, isError: true);
      }
      if (next.utilisateur != null && !_navigated) {
        _navigated = true;
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            context.go('/accueil');
          }
        });
      }
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Inscription', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Nom
              TextFormField(
                controller: _nomController,
                validator: _validerNom,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Prénom
              TextFormField(
                controller: _prenomController,
                validator: _validerPrenom,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  LengthLimitingTextInputFormatter(32),
                ],
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Email
              TextFormField(
                controller: _emailController,
                validator: (v) => v!.contains('@') ? null : 'Email invalide',
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Mot de passe : exactement 6 caractères
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: _validerMotDePasse,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  helperText: 'Exactement 6 caractères (chiffres, lettres ou symboles)',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (authState.isLoading) const CircularProgressIndicator()
              else BoutonPersonnalise(
                texte: 'S\'inscrire',
                onPressed: _inscrire,
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}