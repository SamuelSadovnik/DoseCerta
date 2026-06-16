export type LinkResponseDto = {
  id: string;
  caregiverId: string;
  dependentId: string;
  caregiverName: string;
  dependentName: string;
  active: boolean;
  createdAt: string;
  deactivatedAt: string | null;
};
