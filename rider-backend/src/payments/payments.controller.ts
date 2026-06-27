import { Controller, Post, Headers, Req, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import * as crypto from 'crypto';
import { WalletService } from '../wallet/wallet.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('payments')
export class PaymentsController {
  constructor(
    private walletService: WalletService,
    private prisma: PrismaService,
  ) {}

  @Post('paystack/webhook')
  async webhook(
    @Headers('x-paystack-signature') signature: string,
    @Req() req: Request,
  ) {
    const hash = crypto
      .createHmac('sha512', process.env.PAYSTACK_SECRET!)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== signature) throw new UnauthorizedException();

    if (req.body.event === 'charge.success') {
      const { amount, customer, reference } = req.body.data;

      const wallet = await this.prisma.wallet.findFirst({
        where: { user: { email: customer.email } },
      });

      if (wallet) {
        await this.walletService.credit(
          wallet.id,
          amount / 100,
          reference,
          req.body,
        );
      }
    }

    return { received: true };
  }
}
