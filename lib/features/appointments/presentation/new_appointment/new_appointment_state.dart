class NewAppointmentState {
  const NewAppointmentState({
    this.doctorName = '',
    this.specialty = '',
    this.date,
    this.time,
    this.location,
    this.dependentId,
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final String doctorName;
  final String specialty;
  final DateTime? date;
  final String? time;
  final String? location;
  final String? dependentId;
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  NewAppointmentState copyWith({
    String? doctorName,
    String? specialty,
    DateTime? date,
    String? time,
    String? location,
    String? dependentId,
    bool? isLoading,
    String? errorMessage,
    bool? success,
    bool clearError = false,
  }) {
    return NewAppointmentState(
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      dependentId: dependentId ?? this.dependentId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
    );
  }
}
