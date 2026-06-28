import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/app/app.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/config/environnement.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environnement.init();
  await initDependances();

  String? initialLink;
  try {
    final appLinks = AppLinks();
    final completer = Completer<Uri>();
    final subscription = appLinks.uriLinkStream.listen(
          (uri) {
        if (!completer.isCompleted) {
          completer.complete(uri);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
    );

    // Attendre jusqu'à 15 secondes (cold start + traitement intent)
    try {
      final uri = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('No initial link'),
      );
      initialLink = uri.toString();
      print('Lien initial capturé : $initialLink');
    } catch (e) {
      print('Pas de lien initial (timeout) : $e');
    } finally {
      subscription.cancel();
    }
  } catch (e) {
    print('Pas de lien initial (erreur) : $e');
    initialLink = null;
  }

  print('initialLink final = $initialLink');

  runApp(ProviderScope(child: MyApp(initialLink: initialLink)));
}