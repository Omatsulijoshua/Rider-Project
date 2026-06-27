import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  
  async onModuleInit() {
    await this.$connect();
    console.log('🟢 Prisma connected successfully');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    console.log('🔴 Prisma disconnected');
  }

  // Optional helper (VERY useful in your Rider app)
  async cleanDb() {
    if (process.env.NODE_ENV === 'production') return;

    const models = Reflect.ownKeys(this).filter((key) => {
      return typeof key === 'string' && !key.startsWith('_') && key !== '$connect' && key !== '$disconnect';
    });

    return Promise.all(
      models.map((modelKey) => {
        const model = (this as any)[modelKey];
        if (model && model.deleteMany) {
          return model.deleteMany();
        }
        return Promise.resolve();
      }),
    );
  }
}