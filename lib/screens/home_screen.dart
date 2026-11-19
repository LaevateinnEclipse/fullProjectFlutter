import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final user = session.user;
    final permissions = session.permissions;
    final entities = [
      (Icons.storefront, 'Мерч', '/merch', 'Каталог вещей группы'),
      (Icons.group, 'Состав', '/members', 'Папа и безымянные гули'),
      (Icons.album, 'Альбомы', '/albums', 'Дискография Ghost'),
      (Icons.music_note, 'Треки', '/tracks', 'Песни альбомов'),
      (Icons.event, 'Концерты', '/concerts', 'Афиша и билеты'),
    ];
    return AppScaffold(
      title: 'Ghost — официальный сайт',
      index: -1,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сайт музыкальной группы Ghost',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                  'Дискография, состав, мерч и афиша. Что можно менять, зависит от роли: фанат ведёт свои билеты, менеджер — концерты, администратор — каталог и пользователей.',
                ),
                const SizedBox(height: 16),
                _sessionCard(context, session, user),
                const SizedBox(height: 24),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  if (permissions.canUseFanPortal)
                    FilledButton.icon(
                        onPressed: () => context.go('/my-tickets'),
                        icon: const Icon(Icons.confirmation_number),
                        label: const Text('Мои билеты')),
                  if (permissions.canUseManagerWorkspace)
                    FilledButton.icon(
                        onPressed: () => context.go('/manager'),
                        icon: const Icon(Icons.tour),
                        label: const Text('Рабочее место менеджера')),
                  if (permissions.canManageUsers)
                    FilledButton.icon(
                        onPressed: () => context.go('/admin/users'),
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text('Пользователи и роли')),
                  if (permissions.canViewStatistics)
                    OutlinedButton.icon(
                        onPressed: () => context.go('/admin/statistics'),
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Статистика группы')),
                ]),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final entity in entities)
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < phoneWidth
                            ? MediaQuery.sizeOf(context).width - 48
                            : 250,
                        child: Card(
                          child: InkWell(
                            onTap: () => context.go(entity.$3),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(entity.$1, size: 28),
                                  const SizedBox(height: 8),
                                  Text(entity.$2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  Text(entity.$4,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionCard(
      BuildContext context, SessionStore session, AppUser? user) {
    final permissions = session.permissions;
    if (user == null) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Expanded(
                child: Text('Войдите, чтобы открыть каталог группы.')),
            FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Войти')),
          ]),
        ),
      );
    }
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Роль: ${permissions.role.title} · ${user.email}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final rule in permissions.summary)
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rule')),
          ],
        ),
      ),
    );
  }
}
