import 'package:flutter/material.dart';

import '../../domain/example.dart';

/// A card widget that displays a single [Example].
class ExampleCard extends StatelessWidget {
  const ExampleCard({super.key, required this.example});

  final Example example;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(example.title),
        trailing: example.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
