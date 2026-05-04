import '../../../../core/enums/account_type.dart';
import '../entities/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String identifier,
    required String password,
  });

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
    bool acceptedTerms = false,
  });

  Future<AuthResult> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    Map<String, String>? additionalInfo,
    List<Map<String, String>>? emergencyContacts,
  });

  Future<AuthResult> getProfile();

  Future<void> logout();
}
