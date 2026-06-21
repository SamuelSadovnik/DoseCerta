import { Transform } from 'class-transformer';
import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

function normalizeBirthDate(value: unknown): unknown {
  if (typeof value !== 'string') return value;

  const trimmed = value.trim();
  const brDate = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(trimmed);
  if (!brDate) return trimmed;

  const [, day, month, year] = brDate;
  return `${year}-${month}-${day}`;
}

export class CreateDependentDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsOptional()
  @Transform(({ value }) => normalizeBirthDate(value))
  @IsDateString()
  birthDate?: string;

  @IsOptional()
  @IsString()
  relationship?: string;
}
