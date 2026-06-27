import { Module } from '@nestjs/common';
import { RolesGuard } from '../auth/roles.guard';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DashboardController } from './dashboard/dashboard.controller';
import { AdminConsoleController } from './console.controller';
import { AdminConsoleService } from './console.service';
import { FinanceController } from './finance/finance.controller';

@Module({
  imports: [PrismaModule],
  controllers: [AdminController, DashboardController, AdminConsoleController, FinanceController],
  providers: [AdminService, AdminConsoleService, RolesGuard],
})
export class AdminModule {}
