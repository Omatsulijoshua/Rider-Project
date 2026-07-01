import { Body, Controller, Get, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { DriverStatus } from '@prisma/client';
import { DriversService } from './drivers.service';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../auth/roles.guard';
import { Role, Roles } from '../auth/roles.decorator';
import { OrdersGateway } from '../orders/orders.gateway';
import { OrdersService } from '../orders/orders.service';

@Controller('drivers')
export class DriversController {
  constructor(
    private readonly driversService: DriversService,
    private readonly ordersGateway: OrdersGateway,
    private readonly ordersService: OrdersService,
  ) {}

  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  async getMe(@Req() req) {
    const userId = req.user.userId;
    return this.driversService.getDriverByUserId(userId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Patch('location')
  async updateLocation(
    @Req() req, 
    @Body() dto: { lat: number; lng: number; orderId?: string }
  ) {
    const userId = req.user.userId;
    const result = await this.driversService.updateLocation(userId, dto.lat, dto.lng);

    this.ordersGateway.emitDriverAvailability(result);
    
    if (dto.orderId && result.isOnline) {
      const tracking = await this.ordersService.buildDriverTrackingPayload(
        dto.orderId,
        dto.lat,
        dto.lng,
        result,
      );
      this.ordersGateway.emitDriverLocation(dto.orderId, dto.lat, dto.lng, result, tracking);
    }
    
    return result;
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Post('status')
  async updateStatus(@Req() req, @Body() dto: { isOnline: boolean }) {
    const userId = req.user.userId;
    const result = await this.driversService.updateStatus(userId, dto.isOnline);
    this.ordersGateway.emitDriverAvailability(result);
    return result;
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Post('location-disabled')
  async markLocationDisabled(@Req() req) {
    const userId = req.user.userId;
    const result = await this.driversService.markLocationDisabled(userId);
    this.ordersGateway.emitDriverAvailability(result);
    return result;
  }

  @Get('nearby')
  async getNearbyDrivers(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radiusKm') radiusKm?: string,
    @Query('vehicleType') vehicleType?: string,
  ) {
    return this.driversService.getNearbyAvailableDrivers(
      Number(lat),
      Number(lng),
      radiusKm ? Number(radiusKm) : 10,
      vehicleType,
    );
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Get('admin/live-map')
  async getAdminDriverMap(
    @Query('vehicleType') vehicleType?: string,
    @Query('status') status?: DriverStatus,
    @Query('minRating') minRating?: string,
    @Query('activeDelivery') activeDelivery?: string,
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
    @Query('radiusKm') radiusKm?: string,
  ) {
    return this.driversService.getAdminDriverMap({
      vehicleType,
      status,
      minRating: minRating ? Number(minRating) : undefined,
      activeDelivery:
        activeDelivery === undefined ? undefined : activeDelivery === 'true',
      lat: lat ? Number(lat) : undefined,
      lng: lng ? Number(lng) : undefined,
      radiusKm: radiusKm ? Number(radiusKm) : undefined,
    });
  }
}
