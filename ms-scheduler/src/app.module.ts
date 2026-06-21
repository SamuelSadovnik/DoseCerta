import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { DbModule } from "./db/db.module";
import { MessagingModule } from "./messaging/messaging.module";
import { SchedulerModule } from "./scheduler/scheduler.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    MessagingModule,
    SchedulerModule,
  ],
})
export class AppModule {}
