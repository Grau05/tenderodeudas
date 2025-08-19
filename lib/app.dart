import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/client_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';
import 'core/db/app_database.dart';
import 'ui/root_shell.dart';
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
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (ctx) => ClientProvider(ctx.read<AppDatabase>())),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (ctx) => DebtProvider(ctx.read<AppDatabase>())),
        ChangeNotifierProvider(create: (ctx) => PaymentProvider(ctx.read<AppDatabase>())),
      ],
      child: MaterialApp(
        title: 'Control de Deudas',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const RootShell(),
        routes: {
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

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: brightness,
  ).copyWith(
    // Acentos azul celeste
    secondary: Colors.lightBlue,
    tertiary: Colors.lightBlueAccent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: base.appBarTheme.copyWith(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 1,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: base.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: base.colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: base.colorScheme.surfaceContainerLowest,
    ),
  );
}
