import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class OrdersGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private nearbyWatchers = new Map<string, { lat: number; lng: number; radiusKm: number; vehicleType?: string }>();

  handleDisconnect(client: Socket) {
    this.nearbyWatchers.delete(client.id);
  }

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
    @MessageBody() data: { lat: number; lng: number; radiusKm?: number; vehicleType?: string },
    @ConnectedSocket() client: Socket,
  ) {
    this.nearbyWatchers.set(client.id, {
      lat: Number(data.lat),
      lng: Number(data.lng),
      radiusKm: Number(data.radiusKm ?? 10),
      vehicleType: data.vehicleType,
    });
    return { status: 'joined', ...data };
  }

  emitOrderUpdate(orderId: string, status: string, data: any) {
    this.server.to(`order_${orderId}`).emit('orderUpdate', { status, ...data });
  }

  emitDriverLocation(
    orderId: string,
    lat: number,
    lng: number,
    driver?: any,
    tracking?: { etaMinutes?: number; phase?: string; distanceKm?: number },
  ) {
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
      etaMinutes: tracking?.etaMinutes ?? 8,
      phase: tracking?.phase ?? 'TRACKING',
      distanceKm: tracking?.distanceKm,
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

    this.emitNearbyDriverAvailability(payload);
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

  private emitNearbyDriverAvailability(driver: any) {
    for (const [socketId, watcher] of this.nearbyWatchers.entries()) {
      const socket = this.server.sockets.sockets.get(socketId);
      if (!socket) {
        this.nearbyWatchers.delete(socketId);
        continue;
      }

      const distanceKm =
        driver.lat !== null && driver.lng !== null
          ? this.calculateDistance(watcher.lat, watcher.lng, driver.lat, driver.lng)
          : Number.POSITIVE_INFINITY;
      const vehicleMatches = !watcher.vehicleType || watcher.vehicleType === driver.vehicleType;
      const isVisible =
        driver.isOnline &&
        driver.status === 'AVAILABLE' &&
        vehicleMatches &&
        Number.isFinite(distanceKm) &&
        distanceKm <= watcher.radiusKm;

      if (isVisible) {
        socket.emit('nearbyDriverUpdate', {
          id: driver.id,
          userId: driver.userId,
          name: driver.name,
          isOnline: true,
          status: driver.status,
          vehicleType: driver.vehicleType,
          rating: driver.rating,
          completedJobs: driver.completedJobs,
          lat: driver.lat,
          lng: driver.lng,
          lastActiveAt: driver.lastActiveAt,
          distanceKm: Math.round(distanceKm * 100) / 100,
          etaMinutes: Math.max(3, Math.ceil((distanceKm / 24) * 60)),
        });
      } else {
        socket.emit('nearbyDriverUnavailable', {
          id: driver.id,
          userId: driver.userId,
        });
      }
    }
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
    const earthRadiusKm = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
