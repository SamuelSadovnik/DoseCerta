import { IsBoolean, IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsIn(['personal', 'caregiver', 'admin'])
  accountType: 'personal' | 'caregiver' | 'admin';

  @IsOptional()
  @IsBoolean()
  acceptedTerms?: boolean;
}
