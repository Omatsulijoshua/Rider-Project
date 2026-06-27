import { IsOptional, IsString } from 'class-validator';

export class KycUpdateDto {
  @IsOptional()
  @IsString()
  reason?: string;
}
