import { Module } from "@nestjs/common";
import { DbModule } from "../db/db.module";
import { DevicesModule } from "../devices/devices.module";
import { MessagingModule } from "../messaging/messaging.module";
import { LinkingClientService } from "./links/linking-client.service";
import { NotificationsController } from "./notifications.controller";
import { NotificationsConsumer } from "./notifications.consumer";
import { NotificationsService } from "./notifications.service";
import { PushService } from "./push/push.service";

@Module({
  imports: [DbModule, DevicesModule, MessagingModule],
  controllers: [NotificationsController],
  providers: [
    LinkingClientService,
    NotificationsConsumer,
    NotificationsService,
    PushService,
  ],
})
export class NotificationsModule {}
