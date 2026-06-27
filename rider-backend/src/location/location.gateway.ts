import {
  WebSocketGateway,
  SubscribeMessage,
  WebSocketServer,
  MessageBody,
} from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ cors: true })
export class LocationGateway {
  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('locationUpdate')
  handleLocation(
    @MessageBody()
    data: {
      rideId: string;
      lat: number;
      lng: number;
    },
  ) {
    this.server.to(data.rideId).emit('driverLocation', data);
  }
}
