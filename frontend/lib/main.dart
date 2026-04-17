import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/material_provider.dart';
import 'presentation/providers/fornecedor_provider.dart';
import 'presentation/providers/ordem_compra_provider.dart';

void main() {
  runApp(const EstoqueApp());
}

class EstoqueApp extends StatelessWidget {
  const EstoqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MaterialProvider()),
        ChangeNotifierProvider(create: (_) => FornecedorProvider()),
        ChangeNotifierProvider(create: (_) => OrdemCompraProvider()),
      ],
      child: MaterialApp.router(
        title: 'EstoqueFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: appRouter,
      ),
    );
  }
}