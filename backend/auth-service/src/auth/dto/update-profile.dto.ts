import {
  IsArray,
  IsEmail,
  IsObject,
  IsOptional,
  IsString,
  MinLength,
} from "class-validator";

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  currentPassword?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  newPassword?: string;

  @IsOptional()
  @IsObject()
  additionalInfo?: Record<string, string>;

  @IsOptional()
  @IsArray()
  emergencyContacts?: Array<Record<string, string>>;
}
