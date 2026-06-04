import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/config_editor/config_editor_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/economy_config/economy_config_screen.dart';
import '../../features/events_manager/events_manager_screen.dart';
import '../../features/globals_manager/globals_manager_screen.dart';
import '../../features/game_logs/game_logs_screen.dart';
import '../../features/logs/logs_screen.dart';
import '../../features/player_stats/player_stats_screen.dart';
import '../../features/players/players_screen.dart';
import '../../features/server_control/server_control_screen.dart';
import '../../features/server_selection/server_selection_screen.dart';
import '../../features/types_manager/types_manager_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/servers',
  routes: [
    // Auth and server selection remain outside the navigation shell.
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/servers',
      name: 'servers',
      builder: (context, state) => const ServerSelectionScreen(),
    ),

    // All post-auth routes wrapped in the MainScaffold shell (Req 10.1, 10.2).
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/control',
          name: 'control',
          builder: (context, state) => const ServerControlScreen(),
        ),
        GoRoute(
          path: '/players',
          name: 'players',
          builder: (context, state) => const PlayersScreen(),
        ),
        GoRoute(
          path: '/config',
          name: 'config',
          builder: (context, state) => const ConfigEditorScreen(),
        ),
        GoRoute(
          path: '/types',
          name: 'types',
          builder: (context, state) => const TypesManagerScreen(),
        ),
        GoRoute(
          path: '/globals',
          name: 'globals',
          builder: (context, state) => const GlobalsManagerScreen(),
        ),
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) => const EventsManagerScreen(),
        ),
        GoRoute(
          path: '/logs',
          name: 'logs',
          builder: (context, state) => const LogsScreen(),
        ),
        GoRoute(
          path: '/game-logs',
          name: 'game-logs',
          builder: (context, state) => const GameLogsScreen(),
        ),
        GoRoute(
          path: '/economy',
          name: 'economy',
          builder: (context, state) => const EconomyConfigScreen(),
        ),
        GoRoute(
          path: '/player-stats',
          name: 'player-stats',
          builder: (context, state) => const PlayerStatsScreen(),
        ),
      ],
    ),
  ],
);
