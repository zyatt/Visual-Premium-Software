import 'package:go_router/go_router.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/estoque/estoque_page.dart';
import '../../presentation/pages/fornecedor/fornecedor_page.dart';
import '../../presentation/pages/comparativo/comparativo_page.dart';
import '../../presentation/pages/ordem_compra/ordem_compra_page.dart';
import '../../presentation/pages/controle_estoque/controle_estoque_page.dart';
import '../../presentation/widgets/common/app_shell.dart';
import '../../presentation/pages/ordem_compra/historico_compras_page.dart';
import '../../presentation/widgets/update_checker_widget.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => UpdateChecker(
        child: AppShell(
          currentRoute: state.matchedLocation,
          child: child,
        ),
      ),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/estoque', builder: (_, __) => const EstoquePage()),
        GoRoute(path: '/fornecedores', builder: (_, __) => const FornecedorPage()),
        GoRoute(path: '/comparativo', builder: (_, __) => const ComparativoPage()),
        GoRoute(path: '/ordens-compra', builder: (_, __) => const OrdemCompraPage()),
        GoRoute(path: '/controle-estoque', builder: (_, __) => const ControleEstoquePage()),
        GoRoute(path: '/historico-compras', builder: (_, __) => const HistoricoComprasPage()),
      ],
    ),
  ],
);