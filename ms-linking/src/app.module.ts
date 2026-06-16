import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { RequestLoggingMiddleware } from "./common/middleware/request-logging.middleware";
import { ResponseInterceptor } from "./common/interceptors/response.interceptor";
import { DbModule } from "./db/db.module";
import { LinksModule } from "./links/links.module";
import { MessagingModule } from "./messaging/messaging.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    MessagingModule,
    LinksModule,
  ],
  providers: [ResponseInterceptor],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggingMiddleware).forRoutes("{*path}");
  }
}
