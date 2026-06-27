import { Controller, Patch, Param, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Role, Roles } from '../auth/roles.decorator';
import { UserStatus } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private prisma: PrismaService) {}

  @Patch('block/:id')
  blockUser(@Param('id') id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.BLOCKED },
    });
  }

  @Patch('unblock/:id')
  unblockUser(@Param('id') id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.ACTIVE },
    });
  }

  @Patch('suspend/:id')
  suspendUser(@Param('id') id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.SUSPENDED },
    });
  }
}
