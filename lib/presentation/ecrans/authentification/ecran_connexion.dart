import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/presentation/widgets/communs/champ_texte_personnalise.dart';
import 'package:help_neighbor/presentation/widgets/communs/bouton_personnalise.dart';

class EcranConnexion extends ConsumerStatefulWidget {
  const EcranConnexion({super.key});

  @override
  ConsumerState<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends ConsumerState<EcranConnexion> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _navigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Help Neighbor', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ChampTextePersonnalise(
                controller: _emailController,
                label: 'Email',
                validator: (v) => v!.contains('@') ? null : 'Email invalide',
              ),
              const SizedBox(height: 16),
              ChampTextePersonnalise(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: true,
                validator: (v) => v!.length >= 6 ? null : '6 caractères min',
              ),
              const SizedBox(height: 24),
              if (authState.isLoading) const CircularProgressIndicator()
              else BoutonPersonnalise(
                texte: 'Se connecter',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ref.read(authProvider.notifier).connexion(
                      _emailController.text,
                      _passwordController.text,
                    );
                  }
                },
              ),
              TextButton(
                onPressed: () => context.push('/inscription'),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}