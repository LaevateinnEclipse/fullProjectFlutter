import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_music_site/core/permissions.dart';
import 'package:ghost_music_site/core/validators.dart';
import 'package:ghost_music_site/models/album.dart';

void main() {
  group('валидаторы альбома', () {
    test('пустое название отклоняется', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
    });

    test('непустое название принимается', () {
      expect(V.required()('Opus Eponymous'), isNull);
    });

    test('год выпуска ограничен диапазоном', () {
      final year = V.integer(min: 1960, max: 2100, label: 'Год');
      expect(year('1950'), isNotNull);
      expect(year('2010'), isNull);
    });

    test('почта контакта проверяется', () {
      expect(V.email()('fan@ghost.se'), isNull);
      expect(V.email()('не-почта'), isNotNull);
    });
  });

  group('разбор модели', () {
    test('неполный JSON альбома не приводит к исключению', () {
      final album = Album.fromJson({'id': 1});
      expect(album.title, '');
      expect(album.memberIds, isEmpty);
      expect(album.year, 2010);
    });

    test('числа из строки преобразуются', () {
      final album = Album.fromJson({
        'id': '7',
        'year': '2018',
        'title': 'Prequelle',
      });
      expect(album.id, 7);
      expect(album.year, 2018);
      expect(album.title, 'Prequelle');
    });
  });

  group('права ролей', () {
    test('менеджер тура не меняет дискографию', () {
      const permissions = Permissions(UserRole.manager);
      expect(permissions.canManageEntity('albums'), isFalse);
      expect(permissions.canManageEntity('merch'), isFalse);
      expect(permissions.canManageEntity('concerts'), isTrue);
      expect(permissions.canManageUsers, isFalse);
    });

    test('фанат ведёт свои билеты и не администрирует сайт', () {
      const permissions = Permissions(UserRole.fan);
      expect(permissions.canClaimTicket, isTrue);
      expect(permissions.canUseFanPortal, isTrue);
      expect(permissions.canManageEntity('concerts'), isFalse);
      expect(permissions.canManageUsers, isFalse);
    });
  });
}
