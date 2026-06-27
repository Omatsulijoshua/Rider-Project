import { SetMetadata } from '@nestjs/common';

/**
 * Role constants (prevents typos in your app)
 */
export enum Role {
  CUSTOMER = 'CUSTOMER',
  DRIVER = 'DRIVER',
  ADMIN = 'ADMIN',
}

/**
 * Metadata key used by RolesGuard
 */
export const ROLES_KEY = 'roles';

/**
 * Roles decorator
 * Example:
 * @Roles(Role.ADMIN)
 */
export const Roles = (...roles: Role[]) =>
  SetMetadata(ROLES_KEY, roles);