import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'features/auth/auth_notifier.dart';

/// Server status color constants (Req 10.5, 2.5).
const kOnlineColor = Colors.green;
const kOfflineColor = Colors.red;
const kTransitionColor = Colors.yellow;

class NitradoServerManagerApp extends ConsumerStatefulWidget {
  const NitradoServerManagerApp({super.key});

  @override
  ConsumerState<NitradoServerManagerApp> createState() =>
      _NitradoServerManagerAppState();
}

class _NitradoServerManagerAppState
    extends ConsumerState<NitradoServerManagerApp> {
  @override
  void initState() {
    super.initState();
    // Attempt to restore a previous session on app start (Req 1.2).
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).tryRestoreSession().then((_) {
        if (!mounted) return;
        final status = ref.read(authNotifierProvider).status;
        if (status == AuthStatus.authenticated) {
          appRouter.go('/servers');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nitrado Server Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: appRouter,
    );
  }
}
