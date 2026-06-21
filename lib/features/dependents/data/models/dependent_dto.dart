import '../../domain/entities/dependent.dart';

class DependentDto {
  const DependentDto({
    required this.id,
    required this.name,
    this.birthDate,
    required this.relationship,
    this.status = DependentStatus.active,
    this.avatarUrl,
    this.statusMessage,
    this.activationCode,
    this.linkedUserId,
    this.linkedAt,
    this.caregiverName,
    this.caregiverEmail,
    this.healthInfo,
    this.emergencyContacts = const [],
  });

  factory DependentDto.fromJson(Map<String, dynamic> json) {
    final birthDateRaw = json['birthDate'] as String?;
    final linkedAtRaw = json['linkedAt'] as String?;

    return DependentDto(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: birthDateRaw == null ? null : DateTime.parse(birthDateRaw),
      relationship: RelationshipType.values.firstWhere(
        (r) => r.name == json['relationship'],
        orElse: () => RelationshipType.other,
      ),
      status: DependentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DependentStatus.active,
      ),
      avatarUrl: json['avatarUrl'] as String?,
      statusMessage: json['statusMessage'] as String?,
      activationCode: json['activationCode'] as String?,
      linkedUserId: json['linkedUserId'] as String?,
      linkedAt: linkedAtRaw == null ? null : DateTime.parse(linkedAtRaw),
      caregiverName: json['caregiverName'] as String?,
      caregiverEmail: json['caregiverEmail'] as String?,
      healthInfo: _parseStringMap(json['healthInfo']),
      emergencyContacts: _parseStringMapList(json['emergencyContacts']),
    );
  }

  final String id;
  final String name;
  final DateTime? birthDate;
  final RelationshipType relationship;
  final DependentStatus status;
  final String? avatarUrl;
  final String? statusMessage;
  final String? activationCode;
  final String? linkedUserId;
  final DateTime? linkedAt;
  final String? caregiverName;
  final String? caregiverEmail;
  final Map<String, String>? healthInfo;
  final List<Map<String, String>> emergencyContacts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDate': birthDate?.toIso8601String(),
    'relationship': relationship.name,
    'status': status.name,
    'avatarUrl': avatarUrl,
    'statusMessage': statusMessage,
    'activationCode': activationCode,
    'linkedUserId': linkedUserId,
    'linkedAt': linkedAt?.toIso8601String(),
    'caregiverName': caregiverName,
    'caregiverEmail': caregiverEmail,
    'healthInfo': healthInfo,
    'emergencyContacts': emergencyContacts,
  };

  Dependent toEntity() => Dependent(
    id: id,
    name: name,
    birthDate: birthDate,
    relationship: relationship,
    status: status,
    avatarUrl: avatarUrl,
    statusMessage: statusMessage,
    activationCode: activationCode,
    linkedUserId: linkedUserId,
    linkedAt: linkedAt,
    caregiverName: caregiverName,
    caregiverEmail: caregiverEmail,
    healthInfo: healthInfo,
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
}
