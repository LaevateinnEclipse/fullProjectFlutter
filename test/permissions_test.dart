import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_music_site/core/permissions.dart';
import 'package:ghost_music_site/core/router.dart';

void main() {
  group('разбор роли', () {
    test('известные роли сайта Ghost разбираются', () {
      expect(UserRole.parse('fan'), UserRole.fan);
      expect(UserRole.parse('ghoul'), UserRole.ghoul);
      expect(UserRole.parse('manager'), UserRole.manager);
      expect(UserRole.parse('admin'), UserRole.admin);
    });

    test('неизвестная роль получает права фаната', () {
      expect(UserRole.parse('root'), UserRole.fan);
      expect(UserRole.parse(null), UserRole.fan);
    });
  });

  group('разные функции ролей', () {
    test('фанат берёт билеты и не меняет каталог', () {
      const permissions = Permissions(UserRole.fan);
      expect(permissions.canClaimTicket, isTrue);
      expect(permissions.canUseFanPortal, isTrue);
      expect(permissions.canManageEntity('albums'), isFalse);
      expect(permissions.canManageEntity('concerts'), isFalse);
      expect(permissions.canManageUsers, isFalse);
    });

    test('гуль только смотрит каталог', () {
      const permissions = Permissions(UserRole.ghoul);
      expect(permissions.canClaimTicket, isFalse);
      expect(permissions.canCreate, isFalse);
      expect(permissions.canManageEntity('concerts'), isFalse);
      expect(permissions.canRead, isTrue);
    });

    test('менеджер ведёт концерты и не трогает справочники', () {
      const permissions = Permissions(UserRole.manager);
      expect(permissions.canManageEntity('concerts'), isTrue);
      expect(permissions.canCreateEntity('concerts'), isTrue);
      expect(permissions.canManageEntity('albums'), isFalse);
      expect(permissions.canManageEntity('merch'), isFalse);
      expect(permissions.canManageEntity('members'), isFalse);
      expect(permissions.canManageEntity('tracks'), isFalse);
      expect(permissions.canHardDelete, isFalse);
      expect(permissions.canUseManagerWorkspace, isTrue);
      expect(permissions.canUseFanPortal, isFalse);
    });

    test('администратор управляет каталогом, удалением и пользователями', () {
      const permissions = Permissions(UserRole.admin);
      expect(permissions.canManageEntity('albums'), isTrue);
      expect(permissions.canManageEntity('tracks'), isTrue);
      expect(permissions.canManageEntity('merch'), isTrue);
      expect(permissions.canManageEntity('members'), isTrue);
      expect(permissions.canHardDelete, isTrue);
      expect(permissions.canRestore, isTrue);
      expect(permissions.canManageUsers, isTrue);
      expect(permissions.canViewStatistics, isTrue);
    });

    test('гость не входит в каталог', () {
      const permissions = Permissions.guest();
      expect(permissions.isAuthenticated, isFalse);
      expect(permissions.canRead, isFalse);
      expect(permissions.role, UserRole.fan);
    });
  });

  group('маршруты', () {
    test('чужой адрес закрыт, свой открыт', () {
      const fan = Permissions(UserRole.fan);
      const manager = Permissions(UserRole.manager);
      const admin = Permissions(UserRole.admin);
      expect(isRouteAllowed('/my-tickets', fan), isTrue);
      expect(isRouteAllowed('/my-tickets', manager), isFalse);
      expect(isRouteAllowed('/manager', manager), isTrue);
      expect(isRouteAllowed('/manager', admin), isFalse);
      expect(isRouteAllowed('/admin/users', admin), isTrue);
      expect(isRouteAllowed('/albums/new', manager), isFalse);
      expect(isRouteAllowed('/concerts/new', manager), isTrue);
      expect(isRouteAllowed('/concerts/3/edit', fan), isFalse);
      expect(isRouteAllowed('/albums', fan), isTrue);
    });
  });
}
