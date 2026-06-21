enum RelationshipType { child, mother, father, spouse, other }

extension RelationshipTypeX on RelationshipType {
  String get label => switch (this) {
    RelationshipType.child => 'Filho',
    RelationshipType.mother => 'Mãe',
    RelationshipType.father => 'Pai',
    RelationshipType.spouse => 'Cônjuge',
    RelationshipType.other => 'Outro',
  };
}

enum DependentStatus { active, pendingConfirmation, overdue }

class Dependent {
  const Dependent({
    required this.id,
    required this.name,
    this.birthDate,
    required this.relationship,
    required this.status,
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

  final String id;
  final String name;
  final DateTime? birthDate;
  final RelationshipType relationship;
  final String? avatarUrl;
  final DependentStatus status;
  final String? statusMessage;

  /// Code generated server-side that the dependent uses to link their own
  /// account to this caregiver-managed registry. `null` until the caregiver
  /// fetches the registry from `/dependents`.
  final String? activationCode;

  /// User id of the dependent if they have already linked their account.
  /// `null` while still in "Modo C" (cuidador marca pelo dependente).
  final String? linkedUserId;
  final DateTime? linkedAt;
  final String? caregiverName;
  final String? caregiverEmail;
  final Map<String, String>? healthInfo;
  final List<Map<String, String>> emergencyContacts;

  bool get isLinked => linkedUserId != null;
}
