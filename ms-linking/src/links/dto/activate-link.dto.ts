import { ApiProperty } from "@nestjs/swagger";
import { IsString, Length, Matches } from "class-validator";

export class ActivateLinkDto {
  @ApiProperty({ example: "A7K92D" })
  @IsString()
  @Length(6, 12)
  @Matches(/^[A-Z0-9]+$/)
  code!: string;
}
