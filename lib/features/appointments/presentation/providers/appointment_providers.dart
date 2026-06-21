import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/page_cache_policy.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../dependents/presentation/providers/care_subject_provider.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

final appointmentRemoteDatasourceProvider =
    Provider<AppointmentRemoteDatasource>((ref) {
      final config = ref.watch(appConfigProvider);
      return config.useMockData
          ? AppointmentRemoteDatasource.mock()
          : AppointmentRemoteDatasource.http(ref.watch(dioProvider));
    });

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl(
    ref.watch(appointmentRemoteDatasourceProvider),
  );
});

final appointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((
  ref,
) async {
  ref.cacheFor(PageCachePolicy.mainTabs);
  final dependentId = await ref.watch(
    currentAppointmentDependentIdProvider.future,
  );
  return ref
      .watch(appointmentRepositoryProvider)
      .getAll(dependentId: dependentId);
});

final currentAppointmentDependentIdProvider =
    FutureProvider.autoDispose<String?>((ref) async {
      return ref.watch(currentCareSubjectDependentIdProvider.future);
    });
