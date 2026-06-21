import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as amqplib from "amqplib";
import type { Channel, ChannelModel } from "amqplib";

@Injectable()
export class RabbitMQService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMQService.name);
  private connection?: ChannelModel;
  private channel?: Channel;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    const url = this.configService.get<string>("RABBITMQ_URL");

    if (!url) {
      this.logger.warn("RABBITMQ_URL not configured; publisher disabled");
      return;
    }

    this.connection = await amqplib.connect(url);
    this.channel = await this.connection.createChannel();

    await this.channel.assertExchange("dosecerta.events", "topic", {
      durable: true,
    });
    await this.channel.assertExchange("dosecerta.dlx", "topic", {
      durable: true,
    });
    await this.channel.assertQueue("ms-scheduler.dead-letter.queue", {
      durable: true,
    });
    await this.channel.bindQueue(
      "ms-scheduler.dead-letter.queue",
      "dosecerta.dlx",
      "scheduler.#",
    );

    this.logger.log("RabbitMQ connection established");
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }

  publish(routingKey: string, payload: unknown) {
    if (!this.channel) {
      this.logger.warn("RabbitMQ channel not initialized; event skipped");
      return false;
    }

    return this.channel.publish(
      "dosecerta.events",
      routingKey,
      Buffer.from(JSON.stringify(payload)),
      {
        contentType: "application/json",
        deliveryMode: 2,
        persistent: true,
        messageId:
          typeof payload === "object" &&
          payload !== null &&
          "correlationId" in payload
            ? String((payload as { correlationId: unknown }).correlationId)
            : undefined,
      },
    );
  }
}
