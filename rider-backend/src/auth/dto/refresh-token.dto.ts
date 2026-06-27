// src/auth/dto/refresh-token.dto.ts
import { IsString, IsNotEmpty } from 'class-validator';

/**
 * DTO for handling refresh token requests.
 * Ensures that refreshToken is always provided as a string.
 */
export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string; // `!` asserts it's definitely present
}
