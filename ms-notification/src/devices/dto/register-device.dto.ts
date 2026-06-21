import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from "class-validator";

export class RegisterDeviceDto {
  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  @IsUUID()
  userId!: string;

  @ApiProperty({ example: "fcm-device-token" })
  @IsString()
  token!: string;

  @ApiProperty({ enum: ["ios", "android", "macos", "web"] })
  @IsIn(["ios", "android", "macos", "web"])
  platform!: "ios" | "android" | "macos" | "web";

  @ApiPropertyOptional({ example: "device-123" })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  deviceId?: string;
}
