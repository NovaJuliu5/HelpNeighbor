import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/coeur/extensions/extensions_context.dart';
import 'package:help_neighbor/donnees/depots/depot_authentification.dart';
import 'package:help_neighbor/presentation/widgets/communs/bouton_personnalise.dart';
import 'package:help_neighbor/presentation/widgets/communs/champ_texte_personnalise.dart';

class EcranMotDePasseOublie extends ConsumerStatefulWidget {
  const EcranMotDePasseOublie({super.key});

  @override
  ConsumerState<EcranMotDePasseOublie> createState() => _EcranMotDePasseOublieState();
}

class _EcranMotDePasseOublieState extends ConsumerState<EcranMotDePasseOublie> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailEnvoye = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _envoyerEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final depot = getIt<DepotAuthentification>();
    final email = _emailController.text.trim();

    final result = await depot.demanderReinitialisationMotDePasse(email);

    setState(() => _isLoading = false);

    result.fold(
          (echec) {
        if (context.mounted) {
          context.showSnackBar(
            echec.message ?? 'Une erreur est survenue.',
            isError: true,
          );
        }
      },
          (succes) {
        setState(() => _emailEnvoye = true);
        if (context.mounted) {
          context.showSnackBar(
            'Un email de réinitialisation vous a été envoyé.',
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
        title: const Text('Mot de passe oublié'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/connexion'),
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
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Réinitialiser votre mot de passe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez l\'adresse email associée à votre compte. Nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  ChampTextePersonnalise(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'exemple@domaine.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir votre adresse email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                    enabled: !_isLoading && !_emailEnvoye,
                  ),
                  const SizedBox(height: 24),

                  if (!_emailEnvoye)
                    BoutonPersonnalise(
                      onPressed: _envoyerEmail,
                      isLoading: _isLoading,
                      texte: 'Envoyer le lien',
                      type: BoutonType.principal,
                    )
                  else
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Email envoyé avec succès !',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Vérifiez votre boîte de réception et suivez les instructions.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        BoutonPersonnalise(
                          onPressed: () => context.go('/connexion'),
                          texte: 'Retour à la connexion',
                          type: BoutonType.secondaire,
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