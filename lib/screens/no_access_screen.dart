import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран отказа. Открытый вручную чужой адрес не должен быть пустым.
/// Сама защита на сервере: обход этого экрана всё равно получит 403.
class NoAccessScreen extends StatelessWidget {
  final String title;
  final String message;

  const NoAccessScreen({
    super.key,
    this.title = 'Недостаточно прав',
    this.message = 'У вашей роли нет доступа к этому разделу сайта Ghost.',
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 56, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('На главную'),
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
