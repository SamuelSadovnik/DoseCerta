import { ApiPropertyOptional } from "@nestjs/swagger";
import { Transform } from "class-transformer";
import { IsIn, IsInt, IsOptional, IsString, Min } from "class-validator";

export class NotificationQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @Transform(({ value }) => Number(value ?? 1))
  @IsInt()
  @Min(1)
  _page = 1;

  @ApiPropertyOptional({ default: 10 })
  @Transform(({ value }) => Number(value ?? 10))
  @IsInt()
  @Min(1)
  _size = 10;

  @ApiPropertyOptional({ example: "sentAt desc" })
  @IsOptional()
  @IsString()
  @IsIn(["sentAt desc", "sentAt asc", "createdAt desc", "createdAt asc"])
  _order: "sentAt desc" | "sentAt asc" | "createdAt desc" | "createdAt asc" =
    "sentAt desc";

  @ApiPropertyOptional({ example: "dose_reminder" })
  @IsOptional()
  @IsString()
  type?: string;
}
