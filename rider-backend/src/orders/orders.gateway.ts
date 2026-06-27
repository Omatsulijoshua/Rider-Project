import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class OrdersGateway {
  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('joinDriverRoom')
  handleJoinDriver(
    @MessageBody() userId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(`driver_${userId}`);
    return { status: 'joined', userId };
  }

  @SubscribeMessage('joinOrder')
  handleJoinOrder(
    @MessageBody() orderId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(`order_${orderId}`);
    return { status: 'joined', orderId };
  }

  emitOrderUpdate(orderId: string, status: string, data: any) {
    this.server.to(`order_${orderId}`).emit('orderUpdate', { status, ...data });
  }

  emitDriverLocation(orderId: string, lat: number, lng: number) {
    this.server.to(`order_${orderId}`).emit('driverLocation', { lat, lng });
  }

  emitOrderRequest(userId: string, orderData: any) {
    console.log(`📡 Emitting newOrderRequest to driver_${userId}`);
    this.server.to(`driver_${userId}`).emit('newOrderRequest', orderData);
  }

  broadcastDebug(message: string) {
    console.log(`🛠️ DEBUG: ${message}`);
    this.server.emit('debugLog', { message, timestamp: new Date().toISOString() });
  }

  @SubscribeMessage('sendMessage')
  handleSendMessage(
    @MessageBody() data: { orderId: string; content: string; senderId: string },
  ) {
    this.server.to(`order_${data.orderId}`).emit('newMessage', data);
  }

  emitNewMessage(orderId: string, message: any) {
    this.server.to(`order_${orderId}`).emit('newMessage', message);
  }
}
