import {
  WebSocketGateway,
  SubscribeMessage,
  WebSocketServer,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: true })
export class RidesGateway {
  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('joinRide')
  joinRide(
    @MessageBody() rideId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(rideId);

    client.emit('joinedRide', {
      rideId,
      message: 'Joined ride room successfully',
    });
  }
}
