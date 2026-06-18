import 'package:flutter/material.dart';

import '../../features/alerts/presentation/appointment_alert/appointment_alert_page.dart';
import '../../features/alerts/presentation/medication_alert/medication_alert_page.dart';
import '../../admin/presentation/dashboard/admin_dashboard_page.dart';
import '../../admin/presentation/medications_list/admin_medications_page.dart';
import '../../admin/presentation/users_list/admin_users_page.dart';
import '../../features/appointments/presentation/appointment_success/appointment_success_page.dart';
import '../../features/appointments/domain/entities/appointment.dart';
import '../../features/appointments/presentation/appointments_list/appointments_list_page.dart';
import '../../features/appointments/presentation/new_appointment/new_appointment_page.dart';
import '../../features/auth/presentation/account_type/account_type_page.dart';
import '../../features/auth/presentation/login/login_page.dart';
import '../../features/auth/presentation/register/register_page.dart';
import '../../features/auth/presentation/register_success/register_success_page.dart';
import '../../features/dependents/domain/entities/dependent.dart';
import '../../features/dependents/presentation/dependent_detail/dependent_detail_page.dart';
import '../../features/dependents/presentation/dependent_success/dependent_success_page.dart';
import '../../features/dependents/presentation/dependents_list/dependents_list_page.dart';
import '../../features/dependents/presentation/link_dependent/link_dependent_page.dart';
import '../../features/dependents/presentation/new_dependent/new_dependent_page.dart';
import '../../features/home/domain/entities/dose_schedule.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/profile_settings_pages.dart';
import '../../features/stock/presentation/medication_success/medication_success_page.dart';
import '../../features/stock/presentation/new_medication/new_medication_page.dart';
import '../../features/stock/presentation/stock_list/stock_list_page.dart';
import '../../shared/widgets/feedback_page.dart';
import '../enums/account_type.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String accountType = '/account-type';
  static const String register = '/register';
  static const String registerSuccess = '/register-success';
  static const String home = '/home';
  static const String stock = '/stock';
  static const String newMedication = '/new-medication';
  static const String medicationSuccess = '/medication-success';
  static const String appointments = '/appointments';
  static const String newAppointment = '/new-appointment';
  static const String appointmentSuccess = '/appointment-success';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String profileAdditionalInfo = '/profile/additional-info';
  static const String profileEmergencyContacts = '/profile/emergency-contacts';
  static const String profileNotifications = '/profile/notifications';
  static const String profilePrivacySecurity = '/profile/privacy-security';
  static const String profileTheme = '/profile/theme';
  static const String profileAbout = '/profile/about';
  static const String dependents = '/dependents';
  static const String newDependent = '/new-dependent';
  static const String dependentSuccess = '/dependent-success';
  static const String dependentDetail = '/dependents/detail';
  static const String linkDependent = '/dependents/link';
  static const String alertMedication = '/alert/medication';
  static const String alertAppointment = '/alert/appointment';
  static const String feedback = '/feedback';
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminMedications = '/admin/medications';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _build(settings, const LoginPage());
      case accountType:
        return _build(settings, const AccountTypePage());
      case register:
        final type = settings.arguments as AccountType;
        return _build(settings, RegisterPage(accountType: type));
      case registerSuccess:
        final type = settings.arguments as AccountType;
        return _build(settings, RegisterSuccessPage(accountType: type));
      case home:
        return _build(settings, const HomePage());
      case stock:
        return _build(settings, const StockListPage());
      case newMedication:
        return _build(settings, const NewMedicationPage());
      case medicationSuccess:
        return _build(settings, const MedicationSuccessPage());
      case appointments:
        return _build(settings, const AppointmentsListPage());
      case newAppointment:
        final appointment = settings.arguments is Appointment
            ? settings.arguments as Appointment
            : null;
        return _build(settings, NewAppointmentPage(appointment: appointment));
      case appointmentSuccess:
        return _build(settings, const AppointmentSuccessPage());
      case history:
        return _build(settings, const HistoryPage());
      case profile:
        return _build(settings, const ProfilePage());
      case profileAdditionalInfo:
        return _build(settings, const AdditionalInfoPage());
      case profileEmergencyContacts:
        return _build(settings, const EmergencyContactsPage());
      case profileNotifications:
        return _build(settings, const NotificationsSettingsPage());
      case profilePrivacySecurity:
        return _build(settings, const PrivacySecurityPage());
      case profileTheme:
        return _build(settings, const ThemeSettingsPage());
      case profileAbout:
        return _build(settings, const AboutDoseCertaPage());
      case dependents:
        final args = settings.arguments is DependentsListArgs
            ? settings.arguments as DependentsListArgs
            : const DependentsListArgs();
        return _build(settings, DependentsListPage(args: args));
      case newDependent:
        return _build(settings, const NewDependentPage());
      case dependentSuccess:
        final dependent = settings.arguments is Dependent
            ? settings.arguments as Dependent
            : null;
        return _build(settings, DependentSuccessPage(dependent: dependent));
      case dependentDetail:
        final dep = settings.arguments as Dependent;
        return _build(settings, DependentDetailPage(dependent: dep));
      case linkDependent:
        return _build(settings, const LinkDependentPage());
      case alertMedication:
        final dose = settings.arguments is DoseSchedule
            ? settings.arguments as DoseSchedule
            : null;
        return _build(settings, MedicationAlertPage(dose: dose));
      case alertAppointment:
        final appointment = settings.arguments is Appointment
            ? settings.arguments as Appointment
            : null;
        return _build(settings, AppointmentAlertPage(appointment: appointment));
      case feedback:
        final config = settings.arguments as FeedbackPageConfig;
        return _build(settings, FeedbackPage(config: config));
      case adminDashboard:
        return _build(settings, const AdminDashboardPage());
      case adminUsers:
        return _build(settings, const AdminUsersPage());
      case adminMedications:
        return _build(settings, const AdminMedicationsPage());
      default:
        return null;
    }
  }

  static MaterialPageRoute<dynamic> _build(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
