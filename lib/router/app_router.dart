import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/connection/presentation/screens/connection_screen.dart';

part 'app_router.g.dart';

/// Route paths
class RoutePaths {
  RoutePaths._();

  static const String dashboard = '/';
  static const String connection = '/connection';
  static const String board = '/board/:instanceId';
  static const String workUnit = '/work-unit/:instanceId/:workUnitId';
  static const String stream = '/stream/:instanceId/:sessionId';
  static const String settings = '/settings';
}

/// Route names
class RouteNames {
  RouteNames._();

  static const String dashboard = 'dashboard';
  static const String connection = 'connection';
  static const String board = 'board';
  static const String workUnit = 'workUnit';
  static const String stream = 'stream';
  static const String settings = 'settings';
}

/// App router provider
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.connection,
        name: RouteNames.connection,
        builder: (context, state) => const ConnectionScreen(),
      ),
      // TODO: Add more routes as features are implemented
      // GoRoute(
      //   path: RoutePaths.board,
      //   name: RouteNames.board,
      //   builder: (context, state) => BoardScreen(
      //     instanceId: state.pathParameters['instanceId']!,
      //   ),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
