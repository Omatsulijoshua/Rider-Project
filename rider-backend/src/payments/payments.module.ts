import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { FlutterwaveService } from './flutterwave.service';
import { PaystackService } from './paystack.service';
import { WalletModule } from '../wallet/wallet.module'; // if payments need to credit wallet

@Module({
  imports: [PrismaModule, WalletModule], // optional
  controllers: [PaymentsController],
  providers: [PaymentsService, FlutterwaveService, PaystackService],
})
export class PaymentsModule {}
