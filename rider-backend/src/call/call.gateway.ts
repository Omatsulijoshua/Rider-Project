import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  namespace: '/calls',
  cors: {
    origin: '*',
  },
})
export class CallGateway {
  @WebSocketServer()
  server!: Server;

  // ================= JOIN RIDE ROOM =================
  @SubscribeMessage('joinRide')
  handleJoinRide(
    @MessageBody() rideId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(rideId);
    client.emit('joinedRide', { rideId });
  }

  // ================= START CALL =================
  @SubscribeMessage('call:start')
  startCall(
    @MessageBody() data: { rideId: string; from: string },
  ) {
    this.server.to(data.rideId).emit('call:incoming', data);
  }

  // ================= ACCEPT CALL =================
  @SubscribeMessage('call:accept')
  acceptCall(
    @MessageBody() data: { rideId: string },
  ) {
    this.server.to(data.rideId).emit('call:accepted');
  }

  // ================= WEBRTC OFFER =================
  @SubscribeMessage('call:offer')
  handleOffer(
    @MessageBody() data: { rideId: string; offer: any },
  ) {
    this.server.to(data.rideId).emit('call:offer', data.offer);
  }

  // ================= WEBRTC ANSWER =================
  @SubscribeMessage('call:answer')
  handleAnswer(
    @MessageBody() data: { rideId: string; answer: any },
  ) {
    this.server.to(data.rideId).emit('call:answer', data.answer);
  }

  // ================= ICE CANDIDATE =================
  @SubscribeMessage('call:ice')
  handleIce(
    @MessageBody() data: { rideId: string; candidate: any },
  ) {
    this.server.to(data.rideId).emit('call:ice', data.candidate);
  }

  // ================= END CALL =================
  @SubscribeMessage('call:end')
  endCall(
    @MessageBody() data: { rideId: string },
  ) {
    this.server.to(data.rideId).emit('call:ended');
  }
}
