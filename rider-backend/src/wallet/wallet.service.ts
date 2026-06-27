import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WalletService {
  constructor(private prisma: PrismaService) {}

  async getWallet(userId: string) {
    return this.prisma.wallet.findUnique({ where: { userId } });
  }

  async findOrCreateWallet(userId: string, type: 'CUSTOMER' | 'DRIVER') {
    let wallet = await this.getWallet(userId);
    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: {
          userId,
          type,
          balance: 0,
        },
      });
    }
    return wallet;
  }

  async credit(walletId: string, amount: number, source: string = 'RIDE_PAYMENT', reference?: string, meta?: any) {
    return this.prisma.$transaction([
      this.prisma.wallet.update({
        where: { id: walletId },
        data: { balance: { increment: amount } },
      }),
      this.prisma.transaction.create({
        data: {
          walletId,
          amount,
          type: 'CREDIT',
          source: source as any,
          reference,
          meta,
        },
      }),
    ]);
  }

  async debit(walletId: string, amount: number, source: string = 'WITHDRAWAL', reference?: string, meta?: any) {
    const wallet = await this.prisma.wallet.findUnique({ where: { id: walletId } });

    if (!wallet || wallet.balance < amount || wallet.frozen) {
      throw new BadRequestException('Wallet debit not allowed');
    }

    return this.prisma.$transaction([
      this.prisma.wallet.update({
        where: { id: walletId },
        data: { balance: { decrement: amount } },
      }),
      this.prisma.transaction.create({
        data: {
          walletId,
          amount,
          type: 'DEBIT',
          source: source as any,
          reference,
          meta,
        },
      }),
    ]);
  }

  async recordTransaction(walletId: string, amount: number, type: 'CREDIT' | 'DEBIT', source: string, reference?: string, meta?: any) {
    return this.prisma.transaction.create({
      data: {
        walletId,
        amount,
        type,
        source: source as any,
        reference,
        meta,
      },
    });
  }

  async getTransactions(walletId: string) {
    return this.prisma.transaction.findMany({
      where: { walletId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
