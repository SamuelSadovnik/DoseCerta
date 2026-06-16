import { randomUUID } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { RabbitMQService } from "../messaging/rabbitmq.service";
import type { LinkEstablishedEvent } from "./events/link-established.event";
import type { LinkResponseDto } from "./dto/link-response.dto";

@Injectable()
export class LinksMessagingService {
  constructor(private readonly rabbitMQService: RabbitMQService) {}

  async publishLinkEstablished(link: LinkResponseDto) {
    const event: LinkEstablishedEvent = {
      eventType: "LinkEstablished",
      version: "1.0",
      timestamp: new Date().toISOString(),
      correlationId: randomUUID(),
      producer: "ms-linking",
      data: {
        linkId: link.id,
        caregiverId: link.caregiverId,
        dependentId: link.dependentId,
        dependentName: link.dependentName,
        caregiverName: link.caregiverName,
      },
    };

    await this.rabbitMQService.publish("link.established", event);
  }
}
