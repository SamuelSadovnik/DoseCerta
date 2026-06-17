import { Module } from '@nestjs/common';
import { RabbitMQPublisherService } from './rabbitmq-publisher.service';

@Module({
  providers: [RabbitMQPublisherService],
  exports: [RabbitMQPublisherService],
})
export class MessagingModule {}
