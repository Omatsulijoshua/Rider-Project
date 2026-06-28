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

  @SubscribeMessage('joinAdminTracking')
  handleJoinAdminTracking(@ConnectedSocket() client: Socket) {
    client.join('admin_driver_tracking');
    return { status: 'joined', room: 'admin_driver_tracking' };
  }

  @SubscribeMessage('watchNearbyDrivers')
  handleWatchNearbyDrivers(
    @MessageBody() data: { lat: number; lng: number; radiusKm?: number },
    @ConnectedSocket() client: Socket,
  ) {
    client.join('nearby_driver_tracking');
    return { status: 'joined', ...data };
  }

  emitOrderUpdate(orderId: string, status: string, data: any) {
    this.server.to(`order_${orderId}`).emit('orderUpdate', { status, ...data });
  }

  emitDriverLocation(orderId: string, lat: number, lng: number, driver?: any) {
    this.server.to(`order_${orderId}`).emit('driverLocation', {
      lat,
      lng,
      driver: driver
        ? {
            id: driver.id,
            userId: driver.userId,
            isOnline: driver.isOnline,
            status: driver.status,
            vehicleType: driver.vehicleType,
            rating: driver.averageRating,
            completedJobs: driver.totalRatings,
            lastActiveAt: driver.lastActiveAt,
          }
        : undefined,
      etaMinutes: 8,
    });
  }

  emitDriverAvailability(driver: any) {
    const payload = {
      id: driver.id,
      userId: driver.userId,
      name: driver.user?.name,
      phone: driver.user?.phone,
      isOnline: driver.isOnline,
      status: driver.status,
      vehicleType: driver.vehicleType ?? 'bike',
      rating: driver.averageRating,
      completedJobs: driver.totalRatings,
      fraudScore: driver.fraudScore,
      lat: driver.latitude,
      lng: driver.longitude,
      lastActiveAt: driver.lastActiveAt,
    };

    this.server.to('admin_driver_tracking').emit('driverAvailabilityUpdate', payload);

    if (driver.isOnline && driver.status === 'AVAILABLE') {
      this.server.to('nearby_driver_tracking').emit('nearbyDriverUpdate', payload);
    } else {
      this.server.to('nearby_driver_tracking').emit('nearbyDriverUnavailable', {
        id: driver.id,
        userId: driver.userId,
      });
    }
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
