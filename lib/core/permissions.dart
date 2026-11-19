/// Права ролей сайта Ghost.
///
/// Правила здесь повторяют сервер: клиент скрывает недоступные действия,
/// чтобы не нажимать кнопку, которая всё равно вернёт 403. Проверка на
/// клиенте — удобство интерфейса. Настоящая защита только на сервере.
library;

enum UserRole {
  /// Фанат: смотрит каталог и ведёт свои билеты.
  fan(1, 'Фанат'),

  /// Гуль: видит каталог, но не меняет данные и не берёт билеты.
  ghoul(2, 'Гуль'),

  /// Менеджер тура: ведёт афишу концертов.
  manager(3, 'Менеджер тура'),

  /// Администратор: дискография, состав, мерч, пользователи.
  admin(4, 'Администратор');

  const UserRole(this.level, this.title);

  final int level;
  final String title;

  /// Неизвестная роль получает наименьшие права фаната.
  static UserRole parse(String? value) {
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return UserRole.fan;
  }

  bool atLeast(UserRole min) => level >= min.level;

  bool get canManage => atLeast(UserRole.manager);

  bool get canAdminister => atLeast(UserRole.admin);

  bool get isReadOnly => !canManage;
}

/// Справочники, которые меняет только администратор.
const catalogCollections = ['albums', 'tracks', 'merch', 'members'];

class Permissions {
  const Permissions(this.role) : isGuest = false;

  const Permissions.guest()
      : role = UserRole.fan,
        isGuest = true;

  final UserRole role;
  final bool isGuest;

  bool get isAuthenticated => !isGuest;

  bool get canRead => isAuthenticated;

  bool get canUseFanPortal => isAuthenticated && role == UserRole.fan;

  bool get canClaimTicket => canUseFanPortal;

  bool get canUseManagerWorkspace =>
      isAuthenticated && role == UserRole.manager;

  bool get canViewStatistics => isAuthenticated && role == UserRole.admin;

  bool get canManageConcerts =>
      isAuthenticated && (role == UserRole.manager || role == UserRole.admin);

  bool canManageEntity(String collection) =>
      isAuthenticated &&
      (role == UserRole.admin ||
          (role == UserRole.manager && collection == 'concerts'));

  bool canCreateEntity(String collection) => canManageEntity(collection);

  bool get canCreate => role.canManage;

  bool get canManage => canCreate;

  bool get isReadOnly => !canManage;

  bool get canUpdate => role.canManage;

  bool get canSoftDelete => role.canManage;

  bool get canHardDelete => role.canAdminister;

  bool get canRestore => role.canAdminister;

  bool get canBulkDelete => role.canManage;

  bool get canManageUsers => role.canAdminister;

  List<String> get summary => [
        'Просмотр дискографии, состава, мерча и афиши',
        if (canClaimTicket) 'Свои билеты: взять и вернуть',
        if (role == UserRole.manager) 'Управление афишей концертов',
        if (role == UserRole.admin)
          'Управление альбомами, треками, мерчем и составом',
        if (canManageUsers) 'Пользователи и роли',
        if (canViewStatistics) 'Статистика группы',
        if (canSoftDelete) 'Логическое удаление доступных записей',
        if (canRestore) 'Восстановление удалённых записей',
        if (canHardDelete) 'Физическое удаление',
        if (!canManage && !canClaimTicket)
          isAuthenticated
              ? 'Роль «${role.title}» может только смотреть каталог'
              : 'Изменение данных доступно после входа',
      ];
}
