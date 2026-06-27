import { Controller, Get, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Roles, Role } from '../../auth/roles.decorator';
import { RolesGuard } from '../../auth/roles.guard';
import { AuthGuard } from '@nestjs/passport';
import { WithdrawalStatus } from '@prisma/client';

@Controller('admin/finance')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles(Role.ADMIN)
export class FinanceController {
  constructor(private prisma: PrismaService) {}

  @Get('withdrawals')
  async getWithdrawals() {
    return this.prisma.withdrawal.findMany({
      include: {
        wallet: { include: { user: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  @Patch('withdrawals/:id')
  async updateWithdrawal(
    @Param('id') id: string,
    @Body() body: { status: WithdrawalStatus; reason?: string },
  ) {
    const withdrawal = await this.prisma.withdrawal.findUnique({
      where: { id },
      include: { wallet: true },
    });

    if (!withdrawal) throw new Error('Withdrawal request not found');

    // If approving, we already debited the wallet (assuming debit on request)
    // If rejecting, we need to refund the wallet
    if (body.status === WithdrawalStatus.REJECTED && withdrawal.status === WithdrawalStatus.PENDING) {
       await this.prisma.$transaction([
         this.prisma.wallet.update({
           where: { id: withdrawal.walletId },
           data: { balance: { increment: withdrawal.amount } },
         }),
         this.prisma.transaction.create({
           data: {
             walletId: withdrawal.walletId,
             amount: withdrawal.amount,
             type: 'CREDIT',
             source: 'ADJUSTMENT',
             reference: `REFUND-${withdrawal.id}`,
           }
         })
       ]);
    }

    return this.prisma.withdrawal.update({
      where: { id },
      data: { 
        status: body.status,
        reason: body.reason,
      },
    });
  }
}
