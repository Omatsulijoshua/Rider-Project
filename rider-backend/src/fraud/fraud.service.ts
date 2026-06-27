import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FraudService {
  constructor(private prisma: PrismaService) {}

  async run() {
    const suspects = await this.prisma.transaction.groupBy({
      by: ['walletId'],
      _sum: { amount: true },
      where: {
        wallet: { type: 'DRIVER' },
        createdAt: { gte: new Date(Date.now() - 3600000) },
      },
      having: {
        amount: { _sum: { gt: 50000 } },
      },
    });

    for (const s of suspects) {
      await this.prisma.wallet.update({
        where: { id: s.walletId },
        data: { frozen: true },
      });

      await this.prisma.fraudLog.create({
        data: {
          walletId: s.walletId,
          reason: 'High earnings in short time',
        },
      });
    }
  }
}
