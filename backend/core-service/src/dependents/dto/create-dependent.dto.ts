import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateDependentDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @IsOptional()
  @IsString()
  relationship?: string;
}
