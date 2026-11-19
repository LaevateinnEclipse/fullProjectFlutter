import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_music_site/models/album.dart';
import 'package:ghost_music_site/models/album_query.dart';
import 'package:ghost_music_site/models/page_result.dart';
import 'package:ghost_music_site/repositories/album_repository.dart';
import 'package:ghost_music_site/screens/album_list_screen.dart';
import 'package:ghost_music_site/screens/login_screen.dart';
import 'package:ghost_music_site/state/list_notifiers.dart';
import 'package:ghost_music_site/state/session.dart';
import 'package:ghost_music_site/widgets/entity_table.dart';
import 'package:provider/provider.dart';

class _Albums implements AlbumRepository {
  _Albums({this.pending, this.items = const [], this.failure});
  final Completer<PageResult<Album>>? pending;
  final List<Album> items;
  final Object? failure;

  @override
  Future<PageResult<Album>> find(AlbumQuery query, {CancelToken? cancelToken}) {
    if (pending != null) return pending!.future;
    if (failure != null) return Future.error(failure!);
    return Future.value(
        PageResult(items: items, page: 1, size: 10, total: items.length));
  }

  @override
  Future<Album?> findById(int id) async => null;
  @override
  Future<List<Album>> all({bool includeDeleted = false}) async => items;
  @override
  Future<Album> save(Album album) async => album;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> softDeleteMany(List<int> ids) async => ids.length;
  @override
  Future<int> hardDeleteMany(List<int> ids) async => ids.length;
}

const _opus = Album(
  id: 1,
  title: 'Opus Eponymous',
  catalogCode: 'GH-ALB-001',
  albumType: 'studio',
  year: 2010,
  label: 'Rise Above',
);

Future<void> _pumpList(
  WidgetTester tester, {
  required Size size,
  required AlbumRepository albums,
  AppUser? user,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final session = SessionStore()
    ..setUser(user ??
        const AppUser(
            id: 1,
            username: 'admin',
            fullName: 'Администратор',
            email: 'admin@ghost.se',
            role: 'admin'));
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionStore>.value(value: session),
      ChangeNotifierProvider(create: (_) => AlbumListNotifier(albums)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const AlbumListScreen(query: AlbumQuery())),
        GoRoute(path: '/:a', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/:a/:b', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/:a/:b/:c', builder: (_, __) => const SizedBox()),
      ]),
    ),
  ));
}

void main() {
  testWidgets('список показывает загрузку, пока ответ не пришёл',
      (tester) async {
    await _pumpList(tester,
        size: const Size(360, 800), albums: _Albums(pending: Completer()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Альбомы не найдены.'), findsNothing);
  });

  testWidgets('пустой каталог показывает сообщение, а не индикатор',
      (tester) async {
    await _pumpList(tester, size: const Size(768, 900), albums: _Albums());
    await tester.pumpAndSettle();
    expect(find.text('Альбомы не найдены.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка сети предлагает повтор', (tester) async {
    await _pumpList(tester,
        size: const Size(1280, 800),
        albums: _Albums(failure: Exception('нет связи')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось загрузить альбомы'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('вход без логина не отправляется', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final session = SessionStore()..clear();
    await tester.pumpWidget(ChangeNotifierProvider<SessionStore>.value(
      value: session,
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/register', builder: (_, __) => const SizedBox()),
        ]),
      ),
    ));
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Укажите логин'), findsOneWidget);
  });

  testWidgets('фанат не видит создание альбома', (tester) async {
    await _pumpList(
      tester,
      size: const Size(1280, 800),
      albums: _Albums(items: const [_opus]),
      user: const AppUser(
          id: 2,
          username: 'fan',
          fullName: 'Фанат',
          email: 'fan@ghost.se',
          role: 'fan'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Opus Eponymous'), findsOneWidget);
    expect(find.text('Новый альбом'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('четыре ширины не ломают список и сохраняют выделение',
      (tester) async {
    await _pumpList(tester,
        size: const Size(360, 800), albums: _Albums(items: const [_opus]));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    for (final width in [768.0, 1280.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(EntityTable<Album>), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
  });
}
