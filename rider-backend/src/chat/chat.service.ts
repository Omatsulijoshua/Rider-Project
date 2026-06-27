import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async saveMessage(orderId: string, senderId: string, content: string) {
    return this.prisma.message.create({
      data: {
        orderId,
        senderId,
        content,
      },
    });
  }

  async getMessages(orderId: string) {
    return this.prisma.message.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
    });
  }
}
