import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import * as amqplib from 'amqplib';
import type { Channel, ChannelModel } from 'amqplib';

@Injectable()
export class RabbitMQPublisherService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMQPublisherService.name);
  private connection?: ChannelModel;
  private channel?: Channel;

  async onModuleInit() {
    const url = process.env.RABBITMQ_URL;
    if (!url) {
      this.logger.warn('RABBITMQ_URL not configured; domain events disabled');
      return;
    }

    try {
      this.connection = await amqplib.connect(url);
      this.channel = await this.connection.createChannel();
      await this.channel.assertExchange('dosecerta.events', 'topic', {
        durable: true,
      });
      this.logger.log('RabbitMQ publisher connected');
    } catch (error) {
      this.logger.warn(`RabbitMQ publisher disabled: ${this.message(error)}`);
    }
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }

  publish(eventType: string, routingKey: string, data: Record<string, unknown>) {
    if (!this.channel) return;

    const event = {
      eventType,
      version: '1.0',
      timestamp: new Date().toISOString(),
      correlationId: randomUUID(),
      producer: 'core-service',
      data,
    };

    this.channel.publish(
      'dosecerta.events',
      routingKey,
      Buffer.from(JSON.stringify(event)),
      {
        contentType: 'application/json',
        deliveryMode: 2,
        persistent: true,
        messageId: event.correlationId,
      },
    );
  }

  private message(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
  }
}
