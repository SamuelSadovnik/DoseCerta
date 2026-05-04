import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  MinLength,
} from 'class-validator';

export class CreateMedicationDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsString()
  @MinLength(1)
  dosage: string;

  @IsIn(['tablet', 'capsule', 'drop', 'ml', 'mg', 'other'])
  unit: 'tablet' | 'capsule' | 'drop' | 'ml' | 'mg' | 'other';

  @IsInt()
  @Min(1)
  initialQuantity: number;

  @IsString()
  frequency: string;

  @IsInt()
  @Min(1)
  durationDays: number;

  @IsOptional()
  @IsUUID()
  dependentId?: string;
}
