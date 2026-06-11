import 'package:go_router/go_router.dart';
import 'package:help_neighbor/presentation/ecrans/authentification/ecran_connexion.dart';
import 'package:help_neighbor/presentation/ecrans/authentification/ecran_inscription.dart';
import 'package:help_neighbor/presentation/ecrans/accueil/ecran_accueil.dart';
import 'package:help_neighbor/presentation/ecrans/service/ecran_detail_service.dart';
import 'package:help_neighbor/presentation/ecrans/demande/ecran_detail_demande.dart';
import 'package:help_neighbor/presentation/ecrans/discussion/ecran_liste_discussions.dart';
import 'package:help_neighbor/presentation/ecrans/profil/ecran_profil.dart';
import 'package:help_neighbor/presentation/ecrans/demande/ecran_creer_demande.dart';
import 'package:help_neighbor/presentation/ecrans/explorer/ecran_explorer.dart';
import 'package:help_neighbor/presentation/ecrans/notifications/ecran_notifications.dart';
import 'package:help_neighbor/presentation/ecrans/demande/ecran_modifier_demande.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/presentation/ecrans/profil/ecran_modifier_profil.dart';
import 'package:help_neighbor/presentation/ecrans/discussion/ecran_detail_discussion.dart';
import 'package:help_neighbor/presentation/ecrans/service/ecran_creer_service.dart';
import 'package:help_neighbor/presentation/ecrans/admin/ecran_gestion_utilisateurs.dart';
import 'package:help_neighbor/presentation/ecrans/admin/ecran_signalements.dart';

final router = GoRouter(
  initialLocation: '/connexion',
  routes: [
    GoRoute(path: '/connexion', name: 'connexion', builder: (context, state) => const EcranConnexion()),
    GoRoute(path: '/inscription', name: 'inscription', builder: (context, state) => const EcranInscription()),
    GoRoute(path: '/accueil', name: 'accueil', builder: (context, state) => const EcranAccueil()),
    GoRoute(path: '/service/:id', name: 'service_detail', builder: (context, state) => EcranDetailService(id: state.pathParameters['id']!)),
    GoRoute(path: '/demande/:id', name: 'demande_detail', builder: (context, state) => EcranDetailDemande(id: state.pathParameters['id']!)),
    GoRoute(path: '/explorer', name: 'explorer', builder: (context, state) => const EcranExplorer()),
    GoRoute(path: '/creer-demande', name: 'creer_demande', builder: (context, state) => const EcranCreerDemande()),
    GoRoute(path: '/notifications', name: 'notifications', builder: (context, state) => const EcranNotifications()),
    GoRoute(path: '/discussions', name: 'discussions', builder: (context, state) => const EcranListeDiscussions()),
    GoRoute(
      path: '/discussion/:id',
      name: 'discussion_detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final autreNom = extra?['autreNom'] ?? '';
        return EcranDetailDiscussion(conversationId: id, autreNom: autreNom);
      },
    ),
    // Route statique (plus spécifique) d'abord
    GoRoute(path: '/profil/modifier', name: 'modifier_profil', builder: (context, state) => const EcranModifierProfil()),
    // Route dynamique ensuite
    GoRoute(path: '/profil/:id', name: 'profil', builder: (context, state) => EcranProfil(userId: state.pathParameters['id']!)),
    GoRoute(
      path: '/modifier-demande',
      name: 'modifier_demande',
      builder: (context, state) {
        final demande = state.extra as EntiteDemande;
        return EcranModifierDemande(demande: demande);
      },
    ),
    GoRoute(
      path: '/creer-service',
      name: 'creer_service',
      builder: (context, state) => const EcranCreerService(),
    ),
    // Routes admin
    GoRoute(
      path: '/admin/utilisateurs',
      name: 'admin_utilisateurs',
      builder: (context, state) => const EcranGestionUtilisateurs(),
    ),
    GoRoute(
      path: '/admin/signalements',
      name: 'admin_signalements',
      builder: (context, state) => const EcranSignalements(),
    ),
  ],
);