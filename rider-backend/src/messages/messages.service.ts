import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  async createMessage(orderId: string, senderId: string, content: string) {
    return this.prisma.message.create({
      data: {
        orderId,
        senderId,
        content,
      },
    });
  }

  async getOrderMessages(orderId: string) {
    return this.prisma.message.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
    });
  }
}
