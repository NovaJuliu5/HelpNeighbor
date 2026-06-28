import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_authentification.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_utilisateur.dart';
import 'package:help_neighbor/presentation/widgets/communs/barre_navigation_bas_personnalisee.dart';

class EcranAccueil extends ConsumerWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.utilisateur?.id;
    final primaryColor = Theme.of(context).primaryColor; // Vert du thème

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Help Neighbor',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: primaryColor),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: userId == null
          ? _buildNonConnecte(context)
          : _buildConnecte(context, ref, userId),
      bottomNavigationBar: const BarreNavigationBasPersonnalisee(selectedIndex: 0),
    );
  }

  Widget _buildNonConnecte(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 80, color: primaryColor),
            const SizedBox(height: 20),
            Text(
              'Bienvenue !',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rejoignez la communauté d’entraide de votre quartier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/connexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/inscription'),
              child: Text('Créer un compte', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecte(BuildContext context, WidgetRef ref, String userId) {
    final primaryColor = Theme.of(context).primaryColor;
    final profilAsync = ref.watch(profilUtilisateurProvider(userId));
    final prenom = profilAsync.when(
      data: (user) => user.prenom ?? 'Voisin',
      error: (_, __) => 'Voisin',
      loading: () => '...',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de bienvenue (dégradé de vert)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut $prenom ',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un petit geste aujourd’hui peut changer le quotidien de quelqu’un.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Deux actions principales
          Row(
            children: [
              _ActionTile(
                icon: Icons.help_outline,
                label: 'J’ai besoin\nd’aide',
                color: Colors.orange,
                onTap: () => context.push('/creer-demande'),
              ),
              const SizedBox(width: 16),
              _ActionTile(
                icon: Icons.favorite_outline,
                label: 'Je veux aider\nmes voisins',
                color: primaryColor,
                onTap: () => context.push('/creer-service'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section "Idées du moment"
          const Text(
            ' Idées du moment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _IdeaChip(label: 'Réparation', icon: Icons.build),
              _IdeaChip(label: 'Jardinage', icon: Icons.grass),
              _IdeaChip(label: 'Cours en ligne', icon: Icons.computer),
              _IdeaChip(label: 'Aide ménagère', icon: Icons.cleaning_services),
              _IdeaChip(label: 'Garde d’enfants', icon: Icons.child_care),
              _IdeaChip(label: 'Transport', icon: Icons.directions_car),
            ],
          ),
          const SizedBox(height: 24),

          // Petit rappel statistique
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniStat(
                  count: profilAsync.when(
                    data: (user) => user.nbServices ?? 0,
                    error: (_, __) => 0,
                    loading: () => 0,
                  ),
                  label: 'services',
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                _MiniStat(
                  count: profilAsync.when(
                    data: (user) => user.nbDemandes ?? 0,
                    error: (_, __) => 0,
                    loading: () => 0,
                  ),
                  label: 'demandes',
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                _MiniStat(
                  count: 0,
                  label: 'messages',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 42, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _IdeaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.black87)),
      avatar: Icon(icon, size: 16, color: primaryColor),
      onPressed: () => context.push('/explorer', extra: {'categorie': label}),
      side: BorderSide(color: Colors.grey.shade300, width: 1),
      backgroundColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int count;
  final String label;
  const _MiniStat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}