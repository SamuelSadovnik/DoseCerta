import '../../../../core/enums/account_type.dart';
import '../../domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.cpf,
    this.avatarUrl,
    this.additionalInfo,
    this.emergencyContacts = const [],
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String?,
      accountType: _parseAccountType(json['accountType'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      additionalInfo: _parseStringMap(json['additionalInfo']),
      emergencyContacts: _parseStringMapList(json['emergencyContacts']),
    );
  }

  final String id;
  final String name;
  final String email;
  final String? cpf;
  final AccountType accountType;
  final String? avatarUrl;
  final Map<String, String>? additionalInfo;
  final List<Map<String, String>> emergencyContacts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'cpf': cpf,
    'accountType': accountType.name,
    'avatarUrl': avatarUrl,
    'additionalInfo': additionalInfo,
    'emergencyContacts': emergencyContacts,
  };

  User toEntity() => User(
    id: id,
    name: name,
    email: email,
    cpf: cpf,
    accountType: accountType,
    avatarUrl: avatarUrl,
    additionalInfo: additionalInfo,
    emergencyContacts: emergencyContacts,
  );

  static Map<String, String>? _parseStringMap(Object? raw) {
    if (raw is! Map) return null;
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static List<Map<String, String>> _parseStringMapList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ),
        )
        .toList();
  }

  static AccountType _parseAccountType(String raw) {
    return AccountType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => AccountType.personal,
    );
  }
}
