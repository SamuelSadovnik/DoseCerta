import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../providers/appointment_providers.dart';
import 'new_appointment_state.dart';

class NewAppointmentViewModel extends StateNotifier<NewAppointmentState> {
  NewAppointmentViewModel(this._repository, this._ref, this._appointment)
    : super(_initialState(_appointment));

  final AppointmentRepository _repository;
  final Ref _ref;
  final Appointment? _appointment;

  void onDoctorChanged(String v) =>
      state = state.copyWith(doctorName: v, clearError: true);
  void onSpecialtyChanged(String v) =>
      state = state.copyWith(specialty: v, clearError: true);
  void onDateChanged(DateTime date) =>
      state = state.copyWith(date: date, clearError: true);
  void onTimeChanged(String time) =>
      state = state.copyWith(time: time, clearError: true);
  void onLocationChanged(String v) =>
      state = state.copyWith(location: v, clearError: true);
  void onDependentChanged(String? id) =>
      state = state.copyWith(dependentId: id, clearError: true);

  Future<void> submit() async {
    if (state.isLoading) return;
    if (state.doctorName.trim().isEmpty ||
        state.specialty.trim().isEmpty ||
        state.date == null ||
        state.time == null ||
        state.time!.trim().isEmpty ||
        state.location == null ||
        state.location!.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Preencha todos os campos.');
      return;
    }
    final timeMatch = RegExp(
      r'^([01]?\d|2[0-3]):([0-5]\d)$',
    ).firstMatch(state.time!.trim());
    if (timeMatch == null) {
      state = state.copyWith(
        errorMessage: 'Informe um horário válido. Ex: 14:37',
      );
      return;
    }
    final selectedDay = DateTime(
      state.date!.year,
      state.date!.month,
      state.date!.day,
    );
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    if (selectedDay.isBefore(currentDay)) {
      state = state.copyWith(
        errorMessage: 'Selecione a data de hoje ou uma data futura.',
      );
      return;
    }
    final hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final scheduled = DateTime(
      state.date!.year,
      state.date!.month,
      state.date!.day,
      hour,
      minute,
    );
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_appointment == null) {
        await _repository.create(
          doctorName: state.doctorName.trim(),
          specialty: state.specialty.trim(),
          scheduledAt: scheduled,
          location: state.location!.trim(),
          dependentId: state.dependentId,
        );
      } else {
        await _repository.reschedule(
          id: _appointment.id,
          doctorName: state.doctorName.trim(),
          specialty: state.specialty.trim(),
          scheduledAt: scheduled,
          location: state.location!.trim(),
          dependentId: state.dependentId,
        );
      }
      _ref.invalidate(appointmentsProvider);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível cadastrar.',
        ),
      );
    }
  }

  static NewAppointmentState _initialState(Appointment? appointment) {
    if (appointment == null) return const NewAppointmentState();
    final scheduledAt = appointment.scheduledAt;
    return NewAppointmentState(
      doctorName: appointment.doctorName,
      specialty: appointment.specialty ?? '',
      date: DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day),
      time:
          '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
      location: appointment.location ?? '',
      dependentId: appointment.dependentId,
    );
  }
}

final newAppointmentViewModelProvider = StateNotifierProvider.autoDispose
    .family<NewAppointmentViewModel, NewAppointmentState, Appointment?>((
      ref,
      appointment,
    ) {
      return NewAppointmentViewModel(
        ref.watch(appointmentRepositoryProvider),
        ref,
        appointment,
      );
    });
