export type DeviceResponseDto = {
  id: string;
  userId: string;
  token: string;
  platform: string;
  deviceId: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
} & Record<string, unknown>;
