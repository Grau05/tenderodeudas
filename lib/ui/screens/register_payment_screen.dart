import 'package:flutter/material.dart';

class RegisterPaymentScreen extends StatelessWidget {
  static const routeName = '/register-payment';
  const RegisterPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: const Center(
        child: Text('Registro de pago (pendiente).'),
      ),
    );
  }
}
