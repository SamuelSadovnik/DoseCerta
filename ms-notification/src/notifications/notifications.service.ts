import { Injectable, Logger } from "@nestjs/common";
import { and, asc, count, desc, eq, type SQL } from "drizzle-orm";
import type { PaginatedResult } from "../common/types/paginated-result";
import { DbService } from "../db/db.service";
import {
  notifications,
  processedEvents,
  type Notification,
} from "../db/schema";
import { DevicesService } from "../devices/devices.service";
import type { NotificationQueryDto } from "./dto/notification-query.dto";
import type { NotificationResponseDto } from "./dto/notification-response.dto";
import type { DomainEvent } from "./events/domain-event";
import { LinkingClientService } from "./links/linking-client.service";
import { PushService } from "./push/push.service";

interface NotificationDraft {
  userId: string;
  type: string;
  title: string;
  body: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly dbService: DbService,
    private readonly devicesService: DevicesService,
    private readonly linkingClient: LinkingClientService,
    private readonly pushService: PushService,
  ) {}

  async listByUserId(
    userId: string,
    query: NotificationQueryDto,
  ): Promise<PaginatedResult<NotificationResponseDto>> {
    const page = query._page;
    const limit = query._size;
    const offset = (page - 1) * limit;
    const where = this.buildListWhere(userId, query);
    const orderBy = query._order.endsWith("asc")
      ? asc(
          query._order.startsWith("createdAt")
            ? notifications.createdAt
            : notifications.sentAt,
        )
      : desc(
          query._order.startsWith("createdAt")
            ? notifications.createdAt
            : notifications.sentAt,
        );

    const rows = await this.dbService.db
      .select()
      .from(notifications)
      .where(where)
      .orderBy(orderBy)
      .limit(limit)
      .offset(offset);

    const [totalRow] = await this.dbService.db
      .select({ value: count() })
      .from(notifications)
      .where(where);

    return {
      data: rows.map((row) => this.toResponse(row)),
      total: totalRow?.value ?? 0,
      page,
      limit,
    };
  }

  async handleEvent(event: DomainEvent): Promise<void> {
    const drafts = await this.toNotificationDrafts(event);
    let accepted = false;

    await this.dbService.db.transaction(async (tx) => {
      const [processedEvent] = await tx
        .insert(processedEvents)
        .values({
          correlationId: event.correlationId,
          eventType: event.eventType,
        })
        .onConflictDoNothing()
        .returning();

      if (!processedEvent) {
        this.logger.log(`Duplicate event ignored: ${event.correlationId}`);
        return;
      }

      accepted = true;

      for (const draft of drafts) {
        await tx
          .insert(notifications)
          .values({
            ...draft,
            eventType: event.eventType,
            correlationId: event.correlationId,
            payload: event,
            sentAt: new Date(),
          })
          .onConflictDoNothing();
      }
    });

    if (!accepted) return;

    for (const draft of drafts) {
      const tokens = await this.devicesService.findActiveTokensByUserId(
        draft.userId,
      );
      await this.pushService.send({
        userId: draft.userId,
        tokens,
        title: draft.title,
        body: draft.body,
        data: {
          eventType: event.eventType,
          correlationId: event.correlationId,
        },
      });
    }
  }

  private async toNotificationDrafts(
    event: DomainEvent,
  ): Promise<NotificationDraft[]> {
    switch (event.eventType) {
      case "DoseScheduled":
        return [
          {
            userId: event.data.dependentId ?? event.data.userId,
            type: "dose_reminder",
            title: `Hora de tomar ${event.data.medicationName}`,
            body: `${event.data.dosage}${
              event.data.note ? ` - ${event.data.note}` : ""
            }`,
          },
        ];

      case "DoseTaken":
        return this.caregiverNotification(event.data.dependentId, {
          type: "dose_taken",
          title: "Dose tomada",
          body: `${event.data.dependentName ?? "Dependente"} tomou ${
            event.data.medicationName
          }.`,
        });

      case "DosePostponed":
        return this.caregiverNotification(event.data.dependentId, {
          type: "dose_postponed",
          title: "Dose adiada",
          body: `${event.data.dependentName ?? "Dependente"} adiou ${
            event.data.medicationName
          }.`,
        });

      case "DoseMissed":
        return this.caregiverNotification(event.data.dependentId, {
          type: "dose_missed",
          title: "Dose nao tomada",
          body: `${event.data.dependentName ?? "Dependente"} nao tomou ${
            event.data.medicationName
          } no horario.`,
        });

      case "LinkEstablished":
        return [
          {
            userId: event.data.caregiverId,
            type: "link_established",
            title: "Vinculo confirmado",
            body: `${event.data.dependentName} foi vinculado a sua conta.`,
          },
          {
            userId: event.data.dependentId,
            type: "link_established",
            title: "Responsavel vinculado",
            body: `${event.data.caregiverName} agora acompanha sua rotina.`,
          },
        ];
    }
  }

  private async caregiverNotification(
    dependentId: string | null | undefined,
    notification: Omit<NotificationDraft, "userId">,
  ): Promise<NotificationDraft[]> {
    if (!dependentId) return [];

    const caregiverId =
      await this.linkingClient.findCaregiverIdByDependentId(dependentId);

    if (!caregiverId) return [];

    return [{ userId: caregiverId, ...notification }];
  }

  private buildListWhere(
    userId: string,
    query: NotificationQueryDto,
  ): SQL | undefined {
    const userWhere = eq(notifications.userId, userId);

    if (!query.type) {
      return userWhere;
    }

    return and(userWhere, eq(notifications.type, query.type));
  }

  private toResponse(notification: Notification): NotificationResponseDto {
    return {
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      eventType: notification.eventType,
      correlationId: notification.correlationId,
      payload: notification.payload,
      sentAt: notification.sentAt.toISOString(),
      read: notification.read,
      createdAt: notification.createdAt.toISOString(),
    };
  }

}
