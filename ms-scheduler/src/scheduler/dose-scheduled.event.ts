export type DoseScheduledEvent = {
  eventType: "DoseScheduled";
  version: "1.0";
  timestamp: string;
  correlationId: string;
  producer: "ms-scheduler";
  data: {
    doseId: string;
    userId: string;
    dependentId: string | null;
    medicationName: string;
    dosage: string;
    scheduledAt: string;
    note: string | null;
  };
};

export type DoseReminderEvent = {
  eventType: "DoseReminder";
  version: "1.0";
  timestamp: string;
  correlationId: string;
  producer: "ms-scheduler";
  data: {
    doseId: string;
    userId: string;
    dependentId: string | null;
    medicationName: string;
    dosage: string;
    scheduledAt: string;
    note: string | null;
    remindBeforeMinutes: number;
  };
};

export type AppointmentReminderEvent = {
  eventType: "AppointmentReminder";
  version: "1.0";
  timestamp: string;
  correlationId: string;
  producer: "ms-scheduler";
  data: {
    appointmentId: string;
    userId: string;
    dependentId: string | null;
    doctorName: string;
    specialty: string | null;
    location: string | null;
    scheduledAt: string;
    remindBeforeMinutes: number;
  };
};
