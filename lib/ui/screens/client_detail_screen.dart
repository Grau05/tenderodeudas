import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  static const routeName = '/client-detail';
  const ClientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientId = ModalRoute.of(context)!.settings.arguments as int?;
    return Scaffold(
      appBar: AppBar(title: Text('Cliente #${clientId ?? '-'}')),
      body: const Center(
        child: Text('Detalle del cliente (pendiente de implementar).'),
      ),
    );
  }
}
