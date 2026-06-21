import { Controller, Get, Param, ParseUUIDPipe, Query, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiSecurity, ApiTags } from "@nestjs/swagger";
import { HateoasList } from "../common/decorators/hateoas-list.decorator";
import { ApiKeyGuard } from "../common/guards/api-key.guard";
import { NotificationQueryDto } from "./dto/notification-query.dto";
import type { NotificationResponseDto } from "./dto/notification-response.dto";
import { NotificationsService } from "./notifications.service";

const notificationItemLinks = (item: Record<string, unknown>) => ({
  self: {
    href: `/api/v1/notifications/${item.userId}`,
    method: "GET",
  },
  user: {
    href: `/api/v1/users/${item.userId}`,
    method: "GET",
  },
  all: {
    href: `/api/v1/notifications/${item.userId}`,
    method: "GET",
  },
});

@ApiTags("notifications")
@ApiSecurity("api-key")
@UseGuards(ApiKeyGuard)
@Controller("notifications")
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get(":userId")
  @ApiOperation({ summary: "List notification history for a user" })
  @HateoasList<NotificationResponseDto>({
    basePath: "/api/v1/notifications/:userId",
    itemLinks: notificationItemLinks,
  })
  listByUserId(
    @Param("userId", ParseUUIDPipe) userId: string,
    @Query() query: NotificationQueryDto,
  ) {
    return this.notificationsService.listByUserId(userId, query);
  }
}
