import '../../../../core/enums/account_type.dart';
import '../entities/home_data.dart';

abstract class HomeRepository {
  Future<HomeData> loadHomeData({
    required AccountType accountType,
    String? dependentId,
    bool selfOnly = false,
  });
}
