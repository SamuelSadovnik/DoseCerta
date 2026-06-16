import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

export interface PushMessage {
  userId: string;
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(private readonly configService: ConfigService) {}

  async send(message: PushMessage): Promise<void> {
    const provider = this.configService.get<string>("PUSH_PROVIDER", "mock");

    if (provider !== "fcm") {
      this.logger.log(
        `Mock push to ${message.userId}: ${message.title} - ${message.body}`,
      );
      return;
    }

    const serverKey = this.configService.get<string>("FCM_SERVER_KEY");
    if (!serverKey) {
      this.logger.warn("FCM_SERVER_KEY not configured; push skipped");
      return;
    }

    await Promise.all(
      message.tokens.map((token) =>
        fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${serverKey}`,
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: message.title,
              body: message.body,
            },
            data: message.data ?? {},
          }),
        }),
      ),
    );
  }
}
