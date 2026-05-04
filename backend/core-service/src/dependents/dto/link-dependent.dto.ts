import { IsString, Length } from 'class-validator';

export class LinkDependentDto {
  @IsString()
  @Length(4, 12)
  code: string;
}
