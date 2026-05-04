import { IsInt, Min } from 'class-validator';

export class PostponeDoseDto {
  @IsInt()
  @Min(1)
  minutes: number;
}
