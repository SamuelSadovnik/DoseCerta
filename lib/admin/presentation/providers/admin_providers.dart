import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../features/auth/domain/entities/user.dart';
import '../../../features/stock/domain/entities/medication.dart';
import '../../data/datasources/admin_remote_datasource.dart';

final adminDatasourceProvider = Provider<AdminRemoteDatasource>((ref) {
  return AdminRemoteDatasource.http(ref.watch(dioProvider));
});

final adminUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final ds = ref.watch(adminDatasourceProvider);
  final dtos = await ds.listUsers();
  return dtos.map((e) => e.toEntity()).toList();
});

final adminMedicationsProvider = FutureProvider.autoDispose<List<Medication>>((
  ref,
) async {
  final ds = ref.watch(adminDatasourceProvider);
  final dtos = await ds.listMedications();
  return dtos.map((e) => e.toEntity()).toList();
});
