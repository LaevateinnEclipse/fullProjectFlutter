import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/concert.dart';
import '../state/session.dart';

class RoleRepository {
  RoleRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> summary(String path) =>
      guard(() async => (await dio.get<Map<String, dynamic>>(path)).data ?? {});

  Future<List<Concert>> myTickets() => guard(() async {
        final rows =
            (await dio.get<List<dynamic>>('/account/tickets')).data ?? [];
        return rows.cast<Map<String, dynamic>>().map(Concert.fromJson).toList();
      });

  Future<Concert> claim(int id) => guard(() async {
        final data =
            (await dio.post<Map<String, dynamic>>('/concerts/$id/claim'))
                    .data ??
                {};
        return Concert.fromJson(data);
      });

  Future<void> release(int id) =>
      guard(() => dio.post('/concerts/$id/release'));

  Future<List<AppUser>> users() => guard(() async {
        final data = await summary('/users?size=100');
        return (data['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(AppUser.fromJson)
            .toList();
      });

  Future<void> changeRole(int id, String role) =>
      guard(() => dio.patch('/users/$id/role', data: {'role': role}));
}
