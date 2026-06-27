import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Roles, Role } from '../../auth/roles.decorator';
import { RolesGuard } from '../../auth/roles.guard';
import { AuthGuard } from '@nestjs/passport';
import { WalletType } from '@prisma/client';

@Controller('admin/dashboard')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles(Role.ADMIN)
export class DashboardController {
  constructor(private prisma: PrismaService) {}

  // -----------------------------
  // PLATFORM SUMMARY
  // -----------------------------
  @Get('summary')
  async summary() {
    const platformWallet = await this.prisma.wallet.findFirst({
      where: { type: WalletType.PLATFORM },
    });

    const driverHoldings = await this.prisma.wallet.aggregate({
      _sum: { balance: true },
      where: { type: WalletType.DRIVER },
    });

    const totalB2BVolume = await this.prisma.order.aggregate({
      _sum: { price: true },
      where: { status: 'COMPLETED' },
    });

    const orderStats = await this.prisma.order.groupBy({
      by: ['status'],
      _count: { id: true },
    });

    const activeDrivers = await this.prisma.driver.count({
      where: { isOnline: true },
    });

    return {
      platformBalance: platformWallet?.balance ?? 0,
      driverHoldings: driverHoldings._sum.balance ?? 0,
      totalB2BVolume: totalB2BVolume._sum.price ?? 0,
      orderStats: orderStats.reduce((acc, curr) => ({ ...acc, [curr.status]: curr._count.id }), {}),
      activeDrivers,
    };
  }

  // -----------------------------
  // REVENUE REPORT
  // -----------------------------
  @Get('revenue')
  async revenue(
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.prisma.transaction.aggregate({
      _sum: { amount: true },
      where: {
        wallet: {
          type: WalletType.PLATFORM,
        },
        createdAt: {
          gte: new Date(from),
          lte: new Date(to),
        },
      },
    });
  }
}