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
