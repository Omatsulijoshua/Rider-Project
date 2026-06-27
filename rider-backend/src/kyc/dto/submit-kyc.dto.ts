import { IsArray, IsEnum, IsOptional, IsString } from 'class-validator';

export class SubmitKycDto {
  @IsEnum(['CUSTOMER', 'DRIVER'])
  type!: 'CUSTOMER' | 'DRIVER';

  @IsArray()
  @IsString({ each: true })
  documents!: string[];

  @IsOptional()
  @IsString()
  selfie?: string;
}
