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
