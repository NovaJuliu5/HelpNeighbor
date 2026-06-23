import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/donnees/depots/depot_authentification.dart';
import 'package:help_neighbor/presentation/widgets/communs/bouton_personnalise.dart';
import 'package:help_neighbor/presentation/widgets/communs/champ_texte_personnalise.dart';

class EcranReinitialiserMotDePasse extends ConsumerStatefulWidget {
  final String token;
  const EcranReinitialiserMotDePasse({super.key, required this.token});

  @override
  ConsumerState<EcranReinitialiserMotDePasse> createState() => _EcranReinitialiserMotDePasseState();
}

class _EcranReinitialiserMotDePasseState extends ConsumerState<EcranReinitialiserMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _nouveauController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  bool _reinitialise = false;
  bool _afficherMotDePasse = false;

  @override
  void dispose() {
    _nouveauController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _reinitialiser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final depot = getIt<DepotAuthentification>();
    final nouveauMotDePasse = _nouveauController.text.trim();

    final result = await depot.reinitialiserMotDePasse(
      token: widget.token,
      nouveauMotDePasse: nouveauMotDePasse,
    );

    setState(() => _isLoading = false);

    result.fold(
          (echec) {
        if (context.mounted) {
          context.showSnackBar(
            echec.message ?? 'Erreur lors de la réinitialisation.',
            isError: true,
          );
        }
      },
          (succes) {
        setState(() => _reinitialise = true);
        if (context.mounted) {
          context.showSnackBar(
            'Mot de passe réinitialisé avec succès !',
            isError: false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _reinitialise ? () => context.go('/connexion') : null,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    'Choisissez un nouveau mot de passe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre mot de passe doit contenir au moins 6 caractères.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  ChampTextePersonnalise(
                    controller: _nouveauController,
                    label: 'Nouveau mot de passe',
                    hint: 'minimum 6 caractères',
                    obscureText: !_afficherMotDePasse,
                    keyboardType: TextInputType.visiblePassword,
                    enabled: !_isLoading && !_reinitialise,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir un mot de passe';
                      }
                      if (value.trim().length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  ChampTextePersonnalise(
                    controller: _confirmationController,
                    label: 'Confirmer le mot de passe',
                    hint: 'ressaisissez le mot de passe',
                    obscureText: !_afficherMotDePasse,
                    keyboardType: TextInputType.visiblePassword,
                    enabled: !_isLoading && !_reinitialise,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value.trim() != _nouveauController.text.trim()) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Checkbox(
                        value: _afficherMotDePasse,
                        onChanged: (_isLoading || _reinitialise)
                            ? null
                            : (value) => setState(() => _afficherMotDePasse = value!),
                      ),
                      const Text('Afficher le mot de passe'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (!_reinitialise)
                    BoutonPersonnalise(
                      onPressed: _reinitialiser,
                      isLoading: _isLoading,
                      texte: 'Réinitialiser',
                      type: BoutonType.principal,
                    )
                  else
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Mot de passe mis à jour !',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        BoutonPersonnalise(
                          onPressed: () => context.go('/connexion'),
                          texte: 'Aller à la connexion',
                          type: BoutonType.principal,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}