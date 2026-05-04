import 'dose_schedule.dart';

class HomeData {
  const HomeData({
    required this.dosesTakenToday,
    required this.dosesTotalToday,
    required this.nextDoseTime,
    required this.todayDoses,
  });

  final int dosesTakenToday;
  final int dosesTotalToday;
  final DateTime? nextDoseTime;
  final List<DoseSchedule> todayDoses;
}
