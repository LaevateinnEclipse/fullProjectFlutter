import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/concert.dart';
import '../repositories/role_repository.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import '../data/seed_data.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key, required this.kind});
  final String kind;
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  late Future<Object> _data = _load();
  int? _busy;
  Future<Object> _load() {
    final repo = context.read<RoleRepository>();
    return switch (widget.kind) {
      'fan' => repo.myTickets(),
      'manager' => repo.summary('/manager/workspace'),
      'users' => repo.users(),
      _ => repo.summary('/admin/statistics'),
    };
  }

  void _reload() => setState(() => _data = _load());
  Future<void> _action(int id, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    try {
      await action();
      if (mounted) _reload();
    } on Object catch (e) {
      if (mounted) await showOperationError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String get _title => switch (widget.kind) {
        'fan' => 'Мои билеты',
        'manager' => 'Рабочее место менеджера тура',
        'users' => 'Пользователи и роли',
        _ => 'Статистика Ghost'
      };
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(_title),
          leading: BackButton(onPressed: () => context.go('/')),
          actions: [
            IconButton(
                onPressed: _reload,
                tooltip: 'Обновить',
                icon: const Icon(Icons.refresh)),
            const SessionAction()
          ]),
      body: FutureBuilder<Object>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: StatusView(
                      text: snapshot.error.toString(),
                      error: true,
                      retry: _reload));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: _content(snapshot.data!))));
          }));
  List<Widget> _content(Object data) {
    if (widget.kind == 'fan') {
      final rows = data as List<Concert>;
      return [
        const Text(
            'Здесь только ваши билеты. Запланированный концерт можно вернуть, и он снова появится в афише.'),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: () => context.go('/concerts'),
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Выбрать концерт')),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text(
              'Билетов пока нет. Откройте афишу и возьмите билет на концерт в статусе «план».'),
        for (final concert in rows)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${concert.city} — ${concert.venue}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            '${concert.date.toIso8601String().split('T').first} · ${concert.ticketCode} · ${concert.ticketPrice} ₽'),
                        Text(concertStatusLabel(concert.status)),
                        if (concert.status == 'plan')
                          TextButton.icon(
                              onPressed: _busy != null
                                  ? null
                                  : () => _action(
                                      concert.id,
                                      () => context
                                          .read<RoleRepository>()
                                          .release(concert.id)),
                              icon: const Icon(Icons.undo),
                              label: const Text('Вернуть билет')),
                      ]))),
      ];
    }
    if (widget.kind == 'users') {
      final rows = data as List<AppUser>;
      return [
        const Text(
            'Роль берётся из записи пользователя на сервере. Свою роль администратора изменить нельзя.'),
        const SizedBox(height: 16),
        for (final u in rows)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.fullName,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${u.username} · ${u.email}'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                            key: ValueKey('${u.id}-${u.role}'),
                            initialValue: u.role,
                            decoration: const InputDecoration(
                                labelText: 'Роль',
                                border: OutlineInputBorder()),
                            items: [
                              for (final role in UserRole.values)
                                DropdownMenuItem(
                                    value: role.name, child: Text(role.title))
                            ],
                            onChanged: _busy != null ||
                                    u.id ==
                                        context.read<SessionStore>().user?.id
                                ? null
                                : (role) {
                                    if (role != null) {
                                      _action(
                                          u.id,
                                          () => context
                                              .read<RoleRepository>()
                                              .changeRole(u.id, role));
                                    }
                                  }),
                      ]))),
      ];
    }
    final values = data as Map<String, dynamic>;
    const labels = {
      'users': 'Пользователей',
      'albums': 'Альбомов',
      'tracks': 'Треков',
      'merch': 'Позиций мерча',
      'members': 'Участников',
      'concerts': 'Концертов',
      'plannedConcerts': 'Концертов в плане',
      'claimedTickets': 'Выданных билетов',
      'deletedRecords': 'Записей в корзине',
    };
    return [
      for (final entry in values.entries)
        ListTile(
            title: Text(labels[entry.key] ?? entry.key),
            trailing: Text('${entry.value}',
                style: Theme.of(context).textTheme.titleLarge)),
      if (widget.kind == 'manager') ...[
        const Divider(),
        FilledButton.icon(
            onPressed: () => context.go('/concerts/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить концерт')),
        TextButton(
            onPressed: () => context.go('/concerts'),
            child: const Text('Афиша концертов')),
      ],
    ];
  }
}
