import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';

/// Плашка для роли, которой нельзя менять текущий раздел.
class ReadOnlyNotice extends StatelessWidget {
  final String collection;
  const ReadOnlyNotice({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<SessionStore>().permissions;
    if (permissions.canManageEntity(collection)) return const SizedBox.shrink();
    final text = permissions.canClaimTicket && collection == 'concerts'
        ? 'Билет на запланированный концерт можно взять себе и вернуть в личном кабинете. Справочники доступны для просмотра.'
        : permissions.isAuthenticated
            ? 'Роль «${permissions.role.title}»: этот раздел только для просмотра.'
            : 'Войдите, чтобы открыть каталог.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Icon(Icons.lock_outline, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}

bool canEditCollection(BuildContext context, String collection) =>
    context.watch<SessionStore>().permissions.canManageEntity(collection);

bool canEraseCollection(BuildContext context) =>
    context.watch<SessionStore>().permissions.canHardDelete;

bool canRestoreCollection(BuildContext context) =>
    context.watch<SessionStore>().permissions.canRestore;

bool canClaimConcert(BuildContext context) =>
    context.watch<SessionStore>().permissions.canClaimTicket;
