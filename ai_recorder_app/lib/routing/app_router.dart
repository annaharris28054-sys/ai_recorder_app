import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_page.dart';
import '../screens/main_tab_screen.dart';
import '../screens/record_detail_screen.dart';
import '../state/app_state.dart';

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/login',
    refreshListenable: appState,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'main',
        pageBuilder: (context, state) => const MaterialPage(
          child: MainTabScreen(),
        ),
        routes: [
          GoRoute(
            path: 'record/:id',
            name: 'recordDetail',
            pageBuilder: (context, state) {
              final recordId = int.tryParse(state.pathParameters['id'] ?? '');
              if (recordId == null) {
                return const MaterialPage(
                  child: Scaffold(
                    body: Center(child: Text('记录不存在')),
                  ),
                );
              }
              return MaterialPage(
                child: RecordDetailScreen(recordId: recordId),
              );
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggedIn = appState.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) {
        return '/login';
      }
      if (loggedIn && loggingIn) {
        return '/';
      }
      return null;
    },
  );
}

