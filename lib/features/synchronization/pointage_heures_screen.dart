import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PointageHeuresScreen extends StatelessWidget {
  const PointageHeuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage et Heures'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text('Pointage et Heures - Comming Soon'),
      ),
    );
  }
}
