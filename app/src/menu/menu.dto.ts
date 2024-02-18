import { IsNumber, IsString } from 'class-validator';

export class CreateMenuDto {
  @IsString()
  name: string;

  @IsNumber()
  price: number;
}
