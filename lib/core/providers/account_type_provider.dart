import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/account_type.dart';

final currentAccountTypeProvider = StateProvider<AccountType>(
  (ref) => AccountType.personal,
);
