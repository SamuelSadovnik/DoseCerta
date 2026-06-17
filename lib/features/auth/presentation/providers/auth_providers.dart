import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Picks the right datasource implementation based on [AppConfig.useMockData].
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useMockData
      ? AuthRemoteDatasource.mock()
      : AuthRemoteDatasource.http(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
    ref.watch(authTokenStorageProvider),
    ref.watch(localCacheProvider),
    namespace: config.appInstance,
  );
});

final currentUserProvider = Provider<User?>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthRepositoryImpl.readCurrentUser(
    ref.watch(localCacheProvider),
    namespace: config.appInstance,
  );
});
