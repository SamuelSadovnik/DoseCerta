import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as amqplib from "amqplib";
import type { Channel, ChannelModel, ConsumeMessage } from "amqplib";

type MessageHandler = (payload: unknown, message: ConsumeMessage) => Promise<void>;

@Injectable()
export class RabbitMQService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMQService.name);
  private connection?: ChannelModel;
  private channel?: Channel;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    const url = this.configService.get<string>("RABBITMQ_URL");

    if (!url) {
      this.logger.warn("RABBITMQ_URL not configured; consumer disabled");
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
    await this.channel.assertQueue("ms-notification.events.queue", {
      durable: true,
      arguments: {
        "x-dead-letter-exchange": "dosecerta.dlx",
        "x-dead-letter-routing-key": "notification.failed",
      },
    });
    await this.channel.assertQueue("ms-notification.dead-letter.queue", {
      durable: true,
    });
    await this.channel.bindQueue(
      "ms-notification.dead-letter.queue",
      "dosecerta.dlx",
      "notification.#",
    );

    for (const routingKey of [
      "dose.reminder",
      "dose.scheduled",
      "dose.taken",
      "dose.postponed",
      "dose.missed",
      "link.established",
    ]) {
      await this.channel.bindQueue(
        "ms-notification.events.queue",
        "dosecerta.events",
        routingKey,
      );
    }

    await this.channel.prefetch(10);
    this.logger.log("RabbitMQ connection established");
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }

  async consume(handler: MessageHandler) {
    if (!this.channel) {
      this.logger.warn("RabbitMQ channel not initialized; consumer skipped");
      return;
    }

    await this.channel.consume("ms-notification.events.queue", async (message) => {
      if (!message) return;

      try {
        const payload = JSON.parse(message.content.toString()) as unknown;
        await handler(payload, message);
        this.channel?.ack(message);
      } catch (error) {
        this.logger.error(
          `Message processing failed: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
        this.channel?.nack(message, false, false);
      }
    });
  }
}
