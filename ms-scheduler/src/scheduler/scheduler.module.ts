import { Module } from "@nestjs/common";
import { DbModule } from "../db/db.module";
import { MessagingModule } from "../messaging/messaging.module";
import { SchedulerService } from "./scheduler.service";

@Module({
  imports: [DbModule, MessagingModule],
  providers: [SchedulerService],
})
export class SchedulerModule {}
