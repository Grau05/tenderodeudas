import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/client_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/clients_screen.dart';
import 'ui/screens/client_detail_screen.dart';
import 'ui/screens/new_debt_screen.dart';
import 'ui/screens/register_payment_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/settings_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'Control de Deudas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        initialRoute: DashboardScreen.routeName,
        routes: {
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          ClientsScreen.routeName: (_) => const ClientsScreen(),
          ClientDetailScreen.routeName: (_) => const ClientDetailScreen(),
          NewDebtScreen.routeName: (_) => const NewDebtScreen(),
          RegisterPaymentScreen.routeName: (_) => const RegisterPaymentScreen(),
          ReportsScreen.routeName: (_) => const ReportsScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
