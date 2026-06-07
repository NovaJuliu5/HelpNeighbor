import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/domaine/cas_utilisation/authentification/connexion_usecase.dart';
import 'package:help_neighbor/domaine/cas_utilisation/authentification/inscription_usecase.dart';
import 'package:help_neighbor/domaine/entites/entite_utilisateur.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final connexionUseCase = ConnexionUseCase(getIt());
  final inscriptionUseCase = InscriptionUseCase(getIt());
  return AuthNotifier(connexionUseCase, inscriptionUseCase);
});

class AuthState {
  final bool isLoading;
  final EntiteUtilisateur? utilisateur;
  final Echec? erreur;
  AuthState({this.isLoading = false, this.utilisateur, this.erreur});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ConnexionUseCase _connexion;
  final InscriptionUseCase _inscription;
  AuthNotifier(this._connexion, this._inscription) : super(AuthState());

  Future<void> connexion(String email, String password) async {
    print('🔐 [AUTH] Tentative de connexion pour $email');
    state = AuthState(isLoading: true);
    final result = await _connexion.executer(email, password);
    result.fold(
          (echec) {
        print('❌ [AUTH] Échec connexion : ${echec.message}');
        state = AuthState(erreur: echec);
      },
          (utilisateur) {
        print('✅ [AUTH] Utilisateur reçu après connexion : id=${utilisateur.id}');
        if (!_isValidUuid(utilisateur.id)) {
          print('⚠️ [AUTH] ID invalide détecté : ${utilisateur.id} (n’est pas un UUID)');
        } else {
          print('✅ [AUTH] ID valide (format UUID)');
        }
        state = AuthState(utilisateur: utilisateur);
      },
    );
  }

  Future<void> inscription(String email, String password, String nom, String prenom) async {
    print('📝 [AUTH] Tentative d’inscription pour $email');
    state = AuthState(isLoading: true);
    final result = await _inscription.executer(email, password, nom, prenom);
    result.fold(
          (echec) {
        print('❌ [AUTH] Échec inscription : ${echec.message}');
        state = AuthState(erreur: echec);
      },
          (utilisateur) {
        print('✅ [AUTH] Utilisateur inscrit et connecté : id=${utilisateur.id}');
        if (!_isValidUuid(utilisateur.id)) {
          print('⚠️ [AUTH] ID invalide détecté : ${utilisateur.id} (n’est pas un UUID)');
        } else {
          print('✅ [AUTH] ID valide (format UUID)');
        }
        state = AuthState(utilisateur: utilisateur);
      },
    );
  }

  void deconnexion() {
    print('🚪 [AUTH] Déconnexion de l’utilisateur');
    state = AuthState();
  }

  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }
}