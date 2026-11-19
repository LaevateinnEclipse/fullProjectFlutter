import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../models/album_query.dart';
import '../models/band_member_query.dart';
import '../models/concert_query.dart';
import '../models/merch_query.dart';
import '../models/track_query.dart';
import '../screens/album_form_screen.dart';
import '../screens/album_list_screen.dart';
import '../screens/band_member_form_screen.dart';
import '../screens/band_member_list_screen.dart';
import '../screens/concert_form_screen.dart';
import '../screens/concert_list_screen.dart';
import '../screens/entity_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/merch_form_screen.dart';
import '../screens/merch_list_screen.dart';
import '../screens/no_access_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/register_screen.dart';
import '../widgets/deferred_role_screen.dart';
import '../screens/track_form_screen.dart';
import '../screens/track_list_screen.dart';
import '../state/session.dart';
import '../widgets/dirty_guard.dart';

bool isRouteAllowed(String path, Permissions p) {
  if (!p.isAuthenticated) return false;
  if (path == '/my-tickets') return p.canUseFanPortal;
  if (path == '/manager') return p.canUseManagerWorkspace;
  if (path.startsWith('/admin/')) return p.canManageUsers;
  if (path.endsWith('/new') || path.endsWith('/edit')) {
    final collection = path.split('/')[1];
    return path.endsWith('/new')
        ? p.canCreateEntity(collection)
        : p.canManageEntity(collection);
  }
  return true;
}

String safeReturnLocation(String? from) {
  final uri = Uri.tryParse(from ?? '');
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//') ||
      uri.path == '/login' ||
      uri.path == '/register') {
    return '/';
  }
  return uri.toString();
}

class _GuardedForm extends StatelessWidget {
  final String collection;
  final Widget child;

  const _GuardedForm({required this.collection, required this.child});

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<SessionStore>().permissions;
    if (!permissions.canManageEntity(collection)) {
      return const NoAccessScreen(
        message: 'Эта форма недоступна вашей роли. '
            'Афишу ведёт менеджер тура, справочники — администратор.',
      );
    }
    return child;
  }
}

GoRouter createRouter(SessionStore session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!session.isKnown) return null;
      final isPublic = location == '/login' || location == '/register';
      if (!session.isAuthenticated && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (session.isAuthenticated && isPublic) {
        return safeReturnLocation(state.uri.queryParameters['from']);
      }
      if (session.isAuthenticated &&
          location != '/forbidden' &&
          !isRouteAllowed(location, session.permissions)) {
        return '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (_, __) => const NoAccessScreen()),
      GoRoute(
          path: '/my-tickets',
          builder: (_, __) => const DeferredRoleScreen(kind: 'fan')),
      GoRoute(
          path: '/manager',
          builder: (_, __) => const DeferredRoleScreen(kind: 'manager')),
      GoRoute(
          path: '/admin/users',
          builder: (_, __) => const DeferredRoleScreen(kind: 'users')),
      GoRoute(
          path: '/admin/statistics',
          builder: (_, __) => const DeferredRoleScreen(kind: 'statistics')),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/merch',
          builder: (_, s) => MerchListScreen(query: MerchQuery.fromUri(s.uri))),
      GoRoute(
          path: '/merch/new',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, __) => const _GuardedForm(
              collection: 'merch', child: MerchFormScreen())),
      GoRoute(
          path: '/merch/:id/edit',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, s) => _GuardedForm(
              collection: 'merch',
              child: MerchFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? '')))),
      GoRoute(
          path: '/members',
          builder: (_, s) =>
              BandMemberListScreen(query: BandMemberQuery.fromUri(s.uri))),
      GoRoute(
          path: '/members/new',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, __) => const _GuardedForm(
              collection: 'members', child: BandMemberFormScreen())),
      GoRoute(
          path: '/members/:id/edit',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, s) => _GuardedForm(
              collection: 'members',
              child: BandMemberFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? '')))),
      GoRoute(
          path: '/albums',
          builder: (_, s) => AlbumListScreen(query: AlbumQuery.fromUri(s.uri))),
      GoRoute(
          path: '/albums/new',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, __) => const _GuardedForm(
              collection: 'albums', child: AlbumFormScreen())),
      GoRoute(
          path: '/albums/:id/edit',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, s) => _GuardedForm(
              collection: 'albums',
              child: AlbumFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? '')))),
      GoRoute(
          path: '/tracks',
          builder: (_, s) => TrackListScreen(query: TrackQuery.fromUri(s.uri))),
      GoRoute(
          path: '/tracks/new',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, __) => const _GuardedForm(
              collection: 'tracks', child: TrackFormScreen())),
      GoRoute(
          path: '/tracks/:id/edit',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, s) => _GuardedForm(
              collection: 'tracks',
              child: TrackFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? '')))),
      GoRoute(
          path: '/concerts',
          builder: (_, s) =>
              ConcertListScreen(query: ConcertQuery.fromUri(s.uri))),
      GoRoute(
          path: '/concerts/new',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, __) => const _GuardedForm(
              collection: 'concerts', child: ConcertFormScreen())),
      GoRoute(
          path: '/concerts/:id/edit',
          onExit: (_, __) =>
              !session.isAuthenticated ? true : DirtyGuard.mayLeave(),
          builder: (_, s) => _GuardedForm(
              collection: 'concerts',
              child: ConcertFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? '')))),
      for (final collection in [
        'merch',
        'members',
        'albums',
        'tracks',
        'concerts'
      ])
        GoRoute(
            path: '/$collection/:id',
            builder: (_, state) => EntityDetailScreen(
                collection: collection,
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
    ],
    errorBuilder: (_, s) => NotFoundScreen(location: s.uri.toString()),
  );
}
