import { ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { IsIn, IsInt, IsOptional, IsString, IsUUID, Max, Min } from "class-validator";

export class LinkQueryDto {
  @ApiPropertyOptional({ example: "5e41f39a-7445-4319-9a37-d87524707e37" })
  @IsOptional()
  @IsUUID()
  userId?: string;

  @ApiPropertyOptional({ enum: ["caregiver", "dependent"] })
  @IsOptional()
  @IsIn(["caregiver", "dependent"])
  role?: "caregiver" | "dependent";

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  _page = 1;

  @ApiPropertyOptional({ default: 10, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  _size = 10;

  @ApiPropertyOptional({ example: "createdAt desc" })
  @IsOptional()
  @IsString()
  _order?: string;
}
