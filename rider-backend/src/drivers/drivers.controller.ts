import { Controller, Patch, Body, UseGuards, Req, Query, Post, Get } from '@nestjs/common';
import { DriversService } from './drivers.service';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../auth/roles.guard';
import { Role, Roles } from '../auth/roles.decorator';
import { OrdersGateway } from '../orders/orders.gateway';

@Controller('drivers')
export class DriversController {
  constructor(
    private readonly driversService: DriversService,
    private readonly ordersGateway: OrdersGateway,
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
    
    if (dto.orderId) {
      this.ordersGateway.emitDriverLocation(dto.orderId, dto.lat, dto.lng);
    }
    
    return result;
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Post('status')
  async updateStatus(@Req() req, @Body() dto: { isOnline: boolean }) {
    const userId = req.user.userId;
    return this.driversService.updateStatus(userId, dto.isOnline);
  }
}
