export type CoreDoseDto = {
  id: string;
  userId: string;
  dependentId: string | null;
  medicationName: string;
  dosage: string;
  note: string | null;
  scheduledAt: string;
  status: "pending" | "postponed";
};

export type CoreAppointmentDto = {
  id: string;
  userId: string;
  dependentId: string | null;
  doctorName: string;
  specialty: string | null;
  location: string | null;
  scheduledAt: string;
  status: "scheduled" | "confirmed" | "rescheduled";
};
