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
export class RideGateway {
  @WebSocketServer()
  server!: Server;

  handleConnection(client: Socket) {
    console.log('Client connected:', client.id);
  }

  handleDisconnect(client: Socket) {
    console.log('Client disconnected:', client.id);
  }

  @SubscribeMessage('joinRide')
  handleJoinRide(
    @MessageBody() rideId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(rideId);
  }

  emitRideUpdate(rideId: string, data: any) {
    this.server.to(rideId).emit('rideUpdate', data);
  }
}
