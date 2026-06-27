import {
  WebSocketGateway,
  SubscribeMessage,
  WebSocketServer,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({ cors: true })
export class ChatGateway {
  @WebSocketServer()
  server!: Server;

  constructor(private chatService: ChatService) {}

  @SubscribeMessage('joinChat')
  handleJoinChat(
    @MessageBody() orderId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(`chat_${orderId}`);
    return { status: 'joined', room: `chat_${orderId}` };
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @MessageBody() data: {
      orderId: string;
      senderId: string;
      content: string;
    },
  ) {
    const savedMsg = await this.chatService.saveMessage(
      data.orderId,
      data.senderId,
      data.content,
    );
    this.server.to(`chat_${data.orderId}`).emit('newMessage', savedMsg);
    return savedMsg;
  }
}
