import '../../../../core/enums/account_type.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.cpf,
    this.avatarUrl,
    this.additionalInfo,
    this.emergencyContacts = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? cpf;
  final AccountType accountType;
  final String? avatarUrl;
  final Map<String, String>? additionalInfo;
  final List<Map<String, String>> emergencyContacts;
}
