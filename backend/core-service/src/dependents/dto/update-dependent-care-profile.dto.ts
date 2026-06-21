import { IsArray, IsObject, IsOptional } from 'class-validator';

export class UpdateDependentCareProfileDto {
  @IsOptional()
  @IsObject()
  healthInfo?: Record<string, string>;

  @IsOptional()
  @IsArray()
  emergencyContacts?: Array<Record<string, string>>;
}
