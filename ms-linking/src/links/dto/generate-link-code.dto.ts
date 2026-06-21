import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsInt, IsOptional, IsString, IsUUID, Max, Min } from "class-validator";

export class GenerateLinkCodeDto {
  @ApiProperty({ example: "5e41f39a-7445-4319-9a37-d87524707e37" })
  @IsUUID()
  caregiverId!: string;

  @ApiProperty({ example: "Maria Silva" })
  @IsString()
  caregiverName!: string;

  @ApiProperty({ example: "0bfecefb-48e8-48a3-b2c3-db7bc94236c4" })
  @IsUUID()
  dependentId!: string;

  @ApiProperty({ example: "Joao Silva" })
  @IsString()
  dependentName!: string;

  @ApiPropertyOptional({ minimum: 5, maximum: 1440, default: 60 })
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(1440)
  ttlMinutes?: number;
}
