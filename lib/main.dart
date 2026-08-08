import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/core/router/app_router.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(ByteBeamApp(router: createAppRouter()));
}

/// Root application widget: DI-backed router, theme, and app-scoped blocs.
class ByteBeamApp extends StatelessWidget {
  /// Creates the root application widget.
  const ByteBeamApp({required this.router, super.key});

  /// Application router.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AlertsCubit>.value(value: sl<AlertsCubit>()),
      ],
      child: MaterialApp.router(
        title: 'ByteBeam',
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
