import { Module } from "@nestjs/common";
import { ApiKeyGuard } from "../common/guards/api-key.guard";
import { DbModule } from "../db/db.module";
import { MessagingModule } from "../messaging/messaging.module";
import { LinksController } from "./links.controller";
import { LinksMessagingService } from "./links-messaging.service";
import { LinksService } from "./links.service";

@Module({
  imports: [DbModule, MessagingModule],
  controllers: [LinksController],
  providers: [ApiKeyGuard, LinksMessagingService, LinksService],
})
export class LinksModule {}
