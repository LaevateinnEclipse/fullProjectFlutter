import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'core/router.dart';
import 'core/storage.dart';
import 'repositories/album_repository.dart';
import 'repositories/api_album_repository.dart';
import 'repositories/api_band_member_repository.dart';
import 'repositories/api_concert_repository.dart';
import 'repositories/api_merch_repository.dart';
import 'repositories/api_track_repository.dart';
import 'repositories/band_member_repository.dart';
import 'repositories/concert_repository.dart';
import 'repositories/merch_repository.dart';
import 'repositories/role_repository.dart';
import 'repositories/track_repository.dart';
import 'state/catalog_notifier.dart';
import 'state/list_notifiers.dart';
import 'state/session.dart';
import 'widgets/session_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final preferences = await SharedPreferences.getInstance();
  final migrationNotice = VersionedStore.takeNotice(preferences);
  final session = SessionStore();
  await session.restore(preferences);
  final dio = buildDio(
      tokenProvider: () => session.token,
      refreshTokens: session.refreshTokens,
      onSessionExpired: () => session.logout(
          reason: 'Сессия истекла. Войдите снова.', revoke: false));
  final auth = AuthRepository(dio);
  session.attach(auth);
  await session.restoreUser(auth);
  final router = createRouter(session);
  runApp(MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider<SessionStore>.value(value: session),
        Provider<AuthRepository>(create: (_) => auth),
        Provider<RoleRepository>(create: (_) => RoleRepository(dio)),
        Provider<MerchRepository>(create: (_) => ApiMerchRepository(dio)),
        Provider<BandMemberRepository>(
            create: (_) => ApiBandMemberRepository(dio)),
        Provider<AlbumRepository>(create: (_) => ApiAlbumRepository(dio)),
        Provider<TrackRepository>(create: (_) => ApiTrackRepository(dio)),
        Provider<ConcertRepository>(create: (_) => ApiConcertRepository(dio)),
      ],
      child: Consumer<SessionStore>(
          builder: (context, session, _) => MultiProvider(
                key: ValueKey('${session.isAuthenticated}:${session.user?.id}'),
                providers: [
                  ChangeNotifierProvider(
                      create: (c) =>
                          MerchListNotifier(c.read<MerchRepository>())),
                  ChangeNotifierProvider(
                      create: (c) => BandMemberListNotifier(
                          c.read<BandMemberRepository>())),
                  ChangeNotifierProvider(
                      create: (c) =>
                          AlbumListNotifier(c.read<AlbumRepository>())),
                  ChangeNotifierProvider(
                      create: (c) =>
                          TrackListNotifier(c.read<TrackRepository>())),
                  ChangeNotifierProvider(
                      create: (c) =>
                          ConcertListNotifier(c.read<ConcertRepository>())),
                  ChangeNotifierProvider(
                      create: (c) => CatalogNotifier(
                            albums: c.read<AlbumRepository>(),
                            members: c.read<BandMemberRepository>(),
                            tracks: c.read<TrackRepository>(),
                            merch: c.read<MerchRepository>(),
                            concerts: c.read<ConcertRepository>(),
                          )..load()),
                ],
                child: SessionWatcher(
                    session: session,
                    child: GhostApp(notice: migrationNotice, router: router)),
              ))));
}

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class GhostApp extends StatelessWidget {
  final String? notice;
  final GoRouter router;
  const GhostApp({super.key, this.notice, required this.router});
  @override
  Widget build(BuildContext c) => MaterialApp.router(
      title: 'Ghost',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade800),
          useMaterial3: true),
      routerConfig: router,
      builder: (context, child) {
        final content = notice == null
            ? child ?? const SizedBox.shrink()
            : _MigrationNoticeHost(message: notice!, child: child!);
        return SessionWarning(child: content);
      });
}

class _MigrationNoticeHost extends StatefulWidget {
  final String message;
  final Widget child;
  const _MigrationNoticeHost({required this.message, required this.child});
  @override
  State<_MigrationNoticeHost> createState() => _MigrationNoticeHostState();
}

class _MigrationNoticeHostState extends State<_MigrationNoticeHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(widget.message),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
