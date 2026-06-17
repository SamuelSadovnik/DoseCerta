import { Injectable, Logger, OnApplicationBootstrap } from "@nestjs/common";
import { RabbitMQService } from "../messaging/rabbitmq.service";
import type { DomainEvent } from "./events/domain-event";
import { NotificationsService } from "./notifications.service";

const supportedEvents = new Set([
  "DoseReminder",
  "DoseScheduled",
  "DoseTaken",
  "DosePostponed",
  "DoseMissed",
  "LinkEstablished",
]);

@Injectable()
export class NotificationsConsumer implements OnApplicationBootstrap {
  private readonly logger = new Logger(NotificationsConsumer.name);

  constructor(
    private readonly rabbitMQService: RabbitMQService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async onApplicationBootstrap() {
    await this.rabbitMQService.consume(async (payload) => {
      if (!this.isSupportedEvent(payload)) {
        this.logger.warn("Unsupported event ignored");
        return;
      }

      await this.notificationsService.handleEvent(payload);
    });
  }

  private isSupportedEvent(payload: unknown): payload is DomainEvent {
    return (
      typeof payload === "object" &&
      payload !== null &&
      "eventType" in payload &&
      "correlationId" in payload &&
      "data" in payload &&
      supportedEvents.has(String((payload as { eventType: unknown }).eventType))
    );
  }
}
