import {
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  MinLength,
} from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  @MinLength(2)
  doctorName: string;

  @IsOptional()
  @IsString()
  specialty?: string;

  @IsDateString()
  scheduledAt: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsUUID()
  dependentId?: string;
}
