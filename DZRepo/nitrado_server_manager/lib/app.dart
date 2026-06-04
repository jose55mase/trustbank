import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

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
    // Backend handles Nitrado authentication internally — no token needed
    // in the Flutter app. Go straight to server selection.
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
