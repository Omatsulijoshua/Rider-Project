import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/get-user.decorator';

@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get(':orderId')
  async getMessages(@Param('orderId') orderId: string) {
    return this.messagesService.getOrderMessages(orderId);
  }

  @Post(':orderId')
  async sendMessage(
    @Param('orderId') orderId: string,
    @GetUser() user: any,
    @Body('content') content: string,
  ) {
    return this.messagesService.createMessage(orderId, user.id, content);
  }
}
