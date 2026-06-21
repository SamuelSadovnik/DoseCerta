import { Body, Controller, Post, UseGuards } from "@nestjs/common";
import {
  ApiCreatedResponse,
  ApiOperation,
  ApiSecurity,
  ApiTags,
} from "@nestjs/swagger";
import { HateoasItem } from "../common/decorators/hateoas-item.decorator";
import { ApiKeyGuard } from "../common/guards/api-key.guard";
import type { DeviceResponseDto } from "./dto/device-response.dto";
import { RegisterDeviceDto } from "./dto/register-device.dto";
import { DevicesService } from "./devices.service";

@ApiTags("devices")
@ApiSecurity("api-key")
@UseGuards(ApiKeyGuard)
@Controller("devices")
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post("register")
  @ApiOperation({ summary: "Register or update a push notification token" })
  @ApiCreatedResponse({ description: "Device token registered" })
  @HateoasItem<DeviceResponseDto>({
    itemLinks: (item) => ({
      self: { href: "/api/v1/devices/register", method: "POST" },
      notifications: {
        href: `/api/v1/notifications/${item.userId}`,
        method: "GET",
      },
    }),
  })
  register(@Body() body: RegisterDeviceDto): Promise<DeviceResponseDto> {
    return this.devicesService.register(body);
  }
}
