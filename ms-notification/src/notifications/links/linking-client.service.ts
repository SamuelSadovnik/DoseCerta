import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

interface LinkResponse {
  caregiverId: string;
  dependentId: string;
  active: boolean;
}

interface LinksListResponse {
  data?: LinkResponse[];
}

@Injectable()
export class LinkingClientService {
  private readonly logger = new Logger(LinkingClientService.name);

  constructor(private readonly configService: ConfigService) {}

  async findCaregiverIdByDependentId(
    dependentId: string,
  ): Promise<string | null> {
    const baseUrl = this.configService.get<string>("LINKING_SERVICE_URL");
    const apiKey = this.configService.get<string>("LINKING_SERVICE_API_KEY");

    if (!baseUrl || !apiKey) {
      this.logger.warn("Linking service configuration missing");
      return null;
    }

    const url = new URL("/api/v1/links", baseUrl);
    url.searchParams.set("userId", dependentId);
    url.searchParams.set("role", "dependent");
    url.searchParams.set("_page", "1");
    url.searchParams.set("_size", "1");

    try {
      const response = await fetch(url, {
        headers: { "x-api-key": apiKey },
      });

      if (!response.ok) {
        this.logger.warn(`Linking service returned ${response.status}`);
        return null;
      }

      const payload = (await response.json()) as LinksListResponse;
      return payload.data?.[0]?.caregiverId ?? null;
    } catch (error) {
      this.logger.warn(
        `Could not fetch caregiver link: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return null;
    }
  }
}
