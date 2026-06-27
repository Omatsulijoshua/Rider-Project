import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Role, Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CancelOrderDto } from './dto/cancel-order.dto';
import { CreateOrderDto } from './dto/create-order.dto';
import { QuoteOrderDto } from './dto/quote-order.dto';
import { RateOrderDto } from './dto/rate-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrdersService } from './orders.service';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post('quote')
  async quoteOrder(@Body() dto: QuoteOrderDto) {
    return this.ordersService.quoteOrder(dto);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.CUSTOMER, Role.DRIVER)
  @Post()
  async createOrder(@Req() req, @Body() dto: CreateOrderDto) {
    const userId = req.user.userId;
    const role = req.user.role;
    return this.ordersService.createOrder(userId, dto, role);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Get('available')
  async getAvailableOrders() {
    return this.ordersService.getAvailableOrders();
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Get('all')
  async getAllOrders() {
    return this.ordersService.getAllOrders();
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Get('cancelled/all')
  async getCancelledOrders() {
    return this.ordersService.getCancelledOrders();
  }

  @Get('track/:trackingId')
  async trackOrder(@Param('trackingId') trackingId: string) {
    return this.ordersService.getOrderByTrackingId(trackingId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Get('my-deliveries')
  async getMyDeliveries(@Req() req) {
    const userId = req.user.userId;
    return this.ordersService.getDriverOrders(userId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.CUSTOMER)
  @Get('my-orders')
  async getMyOrders(@Req() req) {
    const userId = req.user.userId;
    return this.ordersService.getCustomerOrders(userId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Patch(':id/accept')
  async acceptOrder(@Req() req, @Param('id') orderId: string) {
    const userId = req.user.userId;
    return this.ordersService.acceptOrder(orderId, userId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.DRIVER)
  @Patch(':id/reject')
  async rejectOrder(@Req() req, @Param('id') orderId: string) {
    const userId = req.user.userId;
    return this.ordersService.rejectOrder(orderId, userId);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN, Role.DRIVER)
  @Patch(':id/status')
  async updateStatus(@Param('id') orderId: string, @Body() dto: UpdateOrderStatusDto) {
    return this.ordersService.updateStatus(orderId, dto.status, dto.proofOfDelivery, dto.verificationCode);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch(':id/cancel')
  async cancelOrder(@Req() req, @Param('id') orderId: string, @Body() dto: CancelOrderDto) {
    const userId = req.user.userId;
    return this.ordersService.cancelOrder(orderId, userId, dto.reason);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.CUSTOMER)
  @Post(':id/rate')
  async rateOrder(@Req() req, @Param('id') orderId: string, @Body() dto: RateOrderDto) {
    const userId = req.user.userId;
    return this.ordersService.rateOrder(orderId, userId, dto.rating, dto.comment);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get(':id')
  async getOrderById(@Param('id') orderId: string) {
    return this.ordersService.getOrderById(orderId);
  }
}
