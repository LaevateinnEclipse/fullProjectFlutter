import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/errors.dart';
import '../state/session.dart';
import 'responsive.dart';

const compactWidth = tableWidth;

class AppScaffold extends StatelessWidget {
  final String title;
  final int index;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onRefresh;
  const AppScaffold(
      {super.key,
      required this.title,
      required this.index,
      required this.child,
      this.actions = const [],
      this.onRefresh});
  @override
  Widget build(BuildContext c) {
    final width = MediaQuery.sizeOf(c).width;
    final compact = width < phoneWidth;
    final destinations = [
      (Icons.home_outlined, 'Главная', '/'),
      (Icons.storefront, 'Мерч', '/merch'),
      (Icons.group, 'Состав', '/members'),
      (Icons.album, 'Альбомы', '/albums'),
      (Icons.music_note, 'Треки', '/tracks'),
      (Icons.event, 'Концерты', '/concerts'),
    ];
    final selected = index < 0 ? 0 : index.clamp(0, destinations.length - 1);
    final app = AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ...actions,
          if (onRefresh != null)
            IconButton(
                tooltip: 'Обновить данные',
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh),
          const SessionAction(),
        ]);
    if (compact) {
      return Scaffold(
          appBar: app,
          body: SafeArea(child: child),
          bottomNavigationBar: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: selected,
              onDestinationSelected: (i) => c.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                      icon: Tooltip(message: d.$2, child: Icon(d.$1)),
                      label: d.$2)
              ]));
    }
    return Scaffold(
        appBar: app,
        body: Row(children: [
          NavigationRail(
              selectedIndex: selected,
              extended: width >= 1280,
              onDestinationSelected: (i) => c.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                      icon: Tooltip(message: d.$2, child: Icon(d.$1)),
                      label: Text(d.$2))
              ]),
          const VerticalDivider(width: 1),
          Expanded(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: contentWidth),
                      child: child)))
        ]));
  }
}

class SessionAction extends StatelessWidget {
  const SessionAction({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final user = session.user;
    if (user == null) {
      return IconButton(
        tooltip: 'Войти',
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.login),
      );
    }
    return PopupMenuButton<String>(
      tooltip: user.fullName,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 14,
                child: Text(user.fullName.isEmpty
                    ? '?'
                    : user.fullName[0].toUpperCase())),
            if (MediaQuery.sizeOf(context).width >= phoneWidth) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(user.fullName, overflow: TextOverflow.ellipsis)),
            ],
          ])),
      onSelected: (value) async {
        if (value == 'home') {
          context.go('/');
          return;
        }
        if (value != 'logout') return;
        await session.logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(session.permissions.role.title,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const PopupMenuItem<String>(value: 'home', child: Text('Главная')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'logout', child: Text('Выйти')),
      ],
    );
  }
}

class StatusView extends StatelessWidget {
  final String text;
  final bool error;
  final VoidCallback? retry;
  const StatusView(
      {super.key, required this.text, this.error = false, this.retry});
  @override
  Widget build(BuildContext c) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(error ? Icons.error_outline : Icons.search_off,
            size: 48, color: error ? Theme.of(c).colorScheme.error : null),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        if (retry != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                  onPressed: retry, child: const Text('Повторить')))
      ]));
}

class Pager extends StatelessWidget {
  final int page, totalPages, total, size;
  final ValueChanged<int> onPage, onSize;
  const Pager(
      {super.key,
      required this.page,
      required this.totalPages,
      required this.total,
      required this.size,
      required this.onPage,
      required this.onSize});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Всего: $total'),
            DropdownButton<int>(
                value: size,
                items: [10, 25, 50]
                    .map((x) => DropdownMenuItem(value: x, child: Text('$x')))
                    .toList(),
                onChanged: (x) {
                  if (x != null) onSize(x);
                }),
            IconButton(
                tooltip: 'Первая страница',
                onPressed: page > 1 ? () => onPage(1) : null,
                icon: const Icon(Icons.first_page)),
            IconButton(
                tooltip: 'Предыдущая страница',
                onPressed: page > 1 ? () => onPage(page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            Text('$page / $totalPages'),
            IconButton(
                tooltip: 'Следующая страница',
                onPressed: page < totalPages ? () => onPage(page + 1) : null,
                icon: const Icon(Icons.chevron_right)),
            IconButton(
                tooltip: 'Последняя страница',
                onPressed: page < totalPages ? () => onPage(totalPages) : null,
                icon: const Icon(Icons.last_page))
          ]));
}

Future<bool> confirm(BuildContext c, String text, {bool hard = false}) async =>
    (await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(
                title:
                    Text(hard ? 'Физическое удаление' : 'Логическое удаление'),
                content: Text(text),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x, false),
                      child: const Text('Отмена')),
                  FilledButton(
                      onPressed: () => Navigator.pop(x, true),
                      child: Text(hard ? 'Стереть' : 'Удалить'))
                ]))) ??
    false;

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

/// Отказ операции не подменяет уже загруженный список экраном ошибки.
Future<void> showOperationError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  if (error is ConflictException || error is LinkedRecordsException) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Операция не выполнена'),
        content: Text('$error\n\nДанные не изменены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
    return;
  }
  toast(context, error.toString());
}
