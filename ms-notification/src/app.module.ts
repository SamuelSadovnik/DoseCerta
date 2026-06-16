import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { RequestLoggingMiddleware } from "./common/middleware/request-logging.middleware";
import { ResponseInterceptor } from "./common/interceptors/response.interceptor";
import { DbModule } from "./db/db.module";
import { DevicesModule } from "./devices/devices.module";
import { MessagingModule } from "./messaging/messaging.module";
import { NotificationsModule } from "./notifications/notifications.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    MessagingModule,
    DevicesModule,
    NotificationsModule,
  ],
  providers: [ResponseInterceptor],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggingMiddleware).forRoutes("{*path}");
  }
}
