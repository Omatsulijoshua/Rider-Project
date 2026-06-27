import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DriversModule } from './drivers/drivers.module';
import { OrdersModule } from './orders/orders.module';
import { WalletModule } from './wallet/wallet.module';
import { KycModule } from './kyc/kyc.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AdminModule } from './admin/admin.module';
import { PrismaModule } from './prisma/prisma.module';
import { ChatModule } from './chat/chat.module';
import { LocationModule } from './location/location.module';
import { PaymentsModule } from './payments/payments.module';

import { GatewayGateway } from './gateway/gateway.gateway';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    DriversModule,
    OrdersModule,
    WalletModule,
    KycModule,
    NotificationsModule,
    AdminModule,
    ChatModule,
    LocationModule,
    PaymentsModule,
  ],
  controllers: [AppController],
  providers: [AppService, GatewayGateway],
})
export class AppModule {}
