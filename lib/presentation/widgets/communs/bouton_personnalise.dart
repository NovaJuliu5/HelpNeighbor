import 'package:flutter/material.dart';

enum BoutonType { principal, secondaire, danger }

class BoutonPersonnalise extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final bool isLoading;
  final BoutonType type;

  const BoutonPersonnalise({
    super.key,
    required this.texte,
    this.onPressed,
    this.isLoading = false,
    this.type = BoutonType.principal,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    switch (type) {
      case BoutonType.principal:
        backgroundColor = Theme.of(context).primaryColor;
        foregroundColor = Colors.white;
        break;
      case BoutonType.secondaire:
        backgroundColor = Colors.transparent;
        foregroundColor = Theme.of(context).primaryColor;
        break;
      case BoutonType.danger:
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: type == BoutonType.secondaire
                ? BorderSide(color: Theme.of(context).primaryColor)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(texte, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}