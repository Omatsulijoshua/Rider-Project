import { IsString, IsNumber, IsOptional, IsArray, IsNotEmpty, IsBoolean } from 'class-validator';

export class CreateOrderDto {
  @IsNumber()
  @IsNotEmpty()
  pickupLat!: number;

  @IsNumber()
  @IsNotEmpty()
  pickupLng!: number;

  @IsNumber()
  @IsNotEmpty()
  dropLat!: number;

  @IsNumber()
  @IsNotEmpty()
  dropLng!: number;

  @IsNumber()
  @IsNotEmpty()
  price!: number;

  @IsString()
  @IsOptional()
  pickupCompanyName?: string;

  @IsString()
  @IsOptional()
  dropoffCompanyName?: string;

  @IsString()
  @IsOptional()
  itemType?: string;

  @IsNumber()
  @IsOptional()
  weight?: number;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  packageImages?: string[];

  @IsString()
  @IsOptional()
  recipientName?: string;

  @IsString()
  @IsOptional()
  recipientPhone?: string;

  @IsString()
  @IsOptional()
  deliveryInstructions?: string;

  @IsString()
  @IsOptional()
  paymentMethod?: 'CASH' | 'WALLET';

  @IsString()
  @IsOptional()
  scheduledAt?: string;

  @IsString()
  @IsOptional()
  pickupAddress?: string;

  @IsString()
  @IsOptional()
  dropoffAddress?: string;

  @IsBoolean()
  @IsOptional()
  priority?: boolean;
}
