import { IsInt, Min } from 'class-validator';

export class RefillMedicationDto {
  @IsInt()
  @Min(1)
  quantity: number;
}
