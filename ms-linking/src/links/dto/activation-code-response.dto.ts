export type ActivationCodeResponseDto = {
  id: string;
  code: string;
  caregiverId: string;
  dependentId: string;
  caregiverName: string;
  dependentName: string;
  used: boolean;
  expiresAt: string;
  createdAt: string;
};
