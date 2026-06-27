import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Role, Roles } from '../auth/roles.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { AdminConsoleService } from './console.service';

@Controller('admin/console')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminConsoleController {
  constructor(private readonly adminConsoleService: AdminConsoleService) {}

  @Get()
  async getConsoleData() {
    return this.adminConsoleService.getConsoleData();
  }
}
