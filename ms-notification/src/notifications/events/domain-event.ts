export type DomainEvent =
  | DoseReminderEvent
  | DoseScheduledEvent
  | DoseTakenEvent
  | DosePostponedEvent
  | DoseMissedEvent
  | LinkEstablishedEvent;

interface BaseEvent<TType extends string, TData> {
  eventType: TType;
  version: string;
  timestamp: string;
  correlationId: string;
  producer: string;
  data: TData;
}

export type DoseScheduledEvent = BaseEvent<
  "DoseScheduled",
  {
    doseId: string;
    userId: string;
    dependentId: string | null;
    medicationName: string;
    dosage: string;
    scheduledAt: string;
    note?: string | null;
  }
>;

export type DoseReminderEvent = BaseEvent<
  "DoseReminder",
  {
    doseId: string;
    userId: string;
    dependentId: string | null;
    medicationName: string;
    dosage: string;
    scheduledAt: string;
    note?: string | null;
    remindBeforeMinutes: number;
  }
>;

export type DoseTakenEvent = BaseEvent<
  "DoseTaken",
  {
    doseId: string;
    userId: string;
    dependentId?: string | null;
    dependentName?: string | null;
    medicationName: string;
    takenAt: string;
  }
>;

export type DosePostponedEvent = BaseEvent<
  "DosePostponed",
  {
    doseId: string;
    userId: string;
    dependentId?: string | null;
    dependentName?: string | null;
    medicationName: string;
    postponedUntil?: string | null;
  }
>;

export type DoseMissedEvent = BaseEvent<
  "DoseMissed",
  {
    doseId: string;
    userId: string;
    dependentId?: string | null;
    dependentName?: string | null;
    medicationName: string;
    scheduledAt: string;
  }
>;

export type LinkEstablishedEvent = BaseEvent<
  "LinkEstablished",
  {
    linkId: string;
    caregiverId: string;
    dependentId: string;
    dependentName: string;
    caregiverName: string;
  }
>;
