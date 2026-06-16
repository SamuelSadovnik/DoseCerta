export type NotificationResponseDto = {
  id: string;
  userId: string;
  type: string;
  title: string;
  body: string;
  eventType: string;
  correlationId: string;
  payload: unknown;
  sentAt: string;
  read: boolean;
  createdAt: string;
} & Record<string, unknown>;
