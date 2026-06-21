import { Injectable } from "@nestjs/common";
import { and, eq } from "drizzle-orm";
import { DbService } from "../db/db.service";
import { devices, type Device } from "../db/schema";
import type { DeviceResponseDto } from "./dto/device-response.dto";
import type { RegisterDeviceDto } from "./dto/register-device.dto";

@Injectable()
export class DevicesService {
  constructor(private readonly dbService: DbService) {}

  async register(input: RegisterDeviceDto): Promise<DeviceResponseDto> {
    const now = new Date();
    const [device] = await this.dbService.db
      .insert(devices)
      .values({
        userId: input.userId,
        token: input.token,
        platform: input.platform,
        deviceId: input.deviceId,
        active: true,
        updatedAt: now,
      })
      .onConflictDoUpdate({
        target: devices.token,
        set: {
          userId: input.userId,
          platform: input.platform,
          deviceId: input.deviceId,
          active: true,
          updatedAt: now,
        },
      })
      .returning();

    return this.toResponse(device);
  }

  async findActiveTokensByUserId(userId: string): Promise<string[]> {
    const rows = await this.dbService.db
      .select({ token: devices.token })
      .from(devices)
      .where(and(eq(devices.userId, userId), eq(devices.active, true)));

    return rows.map((row) => row.token);
  }

  private toResponse(device: Device): DeviceResponseDto {
    return {
      id: device.id,
      userId: device.userId,
      token: device.token,
      platform: device.platform,
      deviceId: device.deviceId,
      active: device.active,
      createdAt: device.createdAt.toISOString(),
      updatedAt: device.updatedAt.toISOString(),
    };
  }
}
