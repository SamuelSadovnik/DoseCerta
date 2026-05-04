enum AccountType { personal, caregiver, admin }

extension AccountTypeX on AccountType {
  bool get isCaregiver => this == AccountType.caregiver;
  bool get isPersonal => this == AccountType.personal;
  bool get isAdmin => this == AccountType.admin;
}
