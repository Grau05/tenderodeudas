import 'package:flutter/material.dart';

class NewDebtScreen extends StatelessWidget {
  static const routeName = '/new-debt';
  const NewDebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva deuda')),
      body: const Center(
        child: Text('Formulario de nueva deuda (pendiente).'),
      ),
    );
  }
}
