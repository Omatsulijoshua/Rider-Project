import { IsBoolean, IsNumber, IsOptional } from 'class-validator';

export class QuoteOrderDto {
  @IsNumber()
  pickupLat!: number;

  @IsNumber()
  pickupLng!: number;

  @IsNumber()
  dropLat!: number;

  @IsNumber()
  dropLng!: number;

  @IsNumber()
  @IsOptional()
  weight?: number;

  @IsBoolean()
  @IsOptional()
  priority?: boolean;
}
