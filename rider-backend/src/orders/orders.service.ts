import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DriverStatus, OrderStatus, WalletType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { QuoteOrderDto } from './dto/quote-order.dto';
import { OrdersGateway } from './orders.gateway';

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private ordersGateway: OrdersGateway,
    private walletService: WalletService,
  ) {}

  quoteOrder(dto: QuoteOrderDto) {
    const distanceKm = this.roundMoney(
      this.calculateDistance(dto.pickupLat, dto.pickupLng, dto.dropLat, dto.dropLng),
    );
    const durationMinutes = Math.max(8, Math.ceil((distanceKm / 24) * 60) + 6);
    const baseFare = 800;
    const distanceFare = this.roundMoney(distanceKm * 180);
    const weightFee = this.roundMoney(Math.max(0, (dto.weight ?? 0) - 5) * 120);
    const priorityFee = dto.priority ? 750 : 0;
    const serviceFee = this.roundMoney((baseFare + distanceFare + weightFee + priorityFee) * 0.08);
    const total = this.roundMoney(baseFare + distanceFare + weightFee + priorityFee + serviceFee);

    return {
      currency: 'NGN',
      distanceKm,
      durationMinutes,
      etaWindowMinutes: {
        min: Math.max(5, durationMinutes - 5),
        max: durationMinutes + 10,
      },
      baseFare,
      distanceFare,
      weightFee,
      priorityFee,
      serviceFee,
      total,
    };
  }

  async createOrder(customerId: string, dto: CreateOrderDto, role: 'CUSTOMER' | 'DRIVER' = 'CUSTOMER') {
    try {
      const quote = this.quoteOrder(dto);
      const trackingId = await this.generateTrackingId();
      const pickupCode = this.generateVerificationCode();
      const dropoffCode = this.generateVerificationCode();

      if (dto.paymentMethod === 'WALLET') {
        const wallet = await this.walletService.findOrCreateWallet(customerId, role);
        if (wallet.balance < quote.total) {
          throw new BadRequestException('Insufficient wallet balance');
        }
        await this.walletService.debit(wallet.id, quote.total, 'WALLET_PAYMENT', undefined, {
          orderPrice: quote.total,
        });
      } else if (dto.paymentMethod === 'CASH') {
        const wallet = await this.walletService.findOrCreateWallet(customerId, role);
        await this.walletService.recordTransaction(wallet.id, 0, 'DEBIT', 'CASH_PAYMENT', undefined, {
          orderPrice: quote.total,
        });
      }

      const order = await this.prisma.order.create({
        data: {
          pickupLat: dto.pickupLat,
          pickupLng: dto.pickupLng,
          dropLat: dto.dropLat,
          dropLng: dto.dropLng,
          price: quote.total,
          quotedDistanceKm: quote.distanceKm,
          quotedDurationMinutes: quote.durationMinutes,
          baseFare: quote.baseFare,
          distanceFare: quote.distanceFare,
          serviceFee: quote.serviceFee,
          priorityFee: quote.priorityFee,
          pickupCode,
          dropoffCode,
          pickupCompanyName: dto.pickupCompanyName,
          dropoffCompanyName: dto.dropoffCompanyName,
          itemType: dto.itemType,
          weight: dto.weight,
          packageImages: dto.packageImages ?? [],
          recipientName: dto.recipientName,
          recipientPhone: dto.recipientPhone,
          deliveryInstructions: dto.deliveryInstructions,
          pickupAddress: dto.pickupAddress,
          dropoffAddress: dto.dropoffAddress,
          paymentMethod: dto.paymentMethod || 'CASH',
          scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
          trackingId,
          customerId,
          status: OrderStatus.REQUESTED,
        },
      });

      this.matchClosestDriver(order.id).catch(err => {
        console.error('Error matching driver in background:', err);
      });

      return order;
    } catch (error: any) {
      console.error('CRITICAL ORDER ERROR:', error);
      throw new BadRequestException(`Order placement failed: ${error.message}`);
    }
  }

  async matchClosestDriver(orderId: string) {
    console.log(`Matching driver for order ${orderId}`);
    this.ordersGateway.broadcastDebug(`Starting match for order ${orderId}`);

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) {
      this.ordersGateway.broadcastDebug(`Order ${orderId} not found`);
      return;
    }

    if (order.status !== OrderStatus.REQUESTED) {
      this.ordersGateway.broadcastDebug(`Order ${order.trackingId} is already ${order.status}`);
      return;
    }

    const [totalDrivers, availableDrivers] = await Promise.all([
      this.prisma.driver.count(),
      this.prisma.driver.findMany({
        where: {
          isOnline: true,
          status: DriverStatus.AVAILABLE,
          userId: { notIn: order.rejectedBy },
        },
        include: {
          user: { select: { id: true, name: true, phone: true } },
        },
      }),
    ]);

    this.ordersGateway.broadcastDebug(
      `DB Stats: ${totalDrivers} total drivers, ${availableDrivers.length} online and available`,
    );

    if (availableDrivers.length === 0) {
      console.log(`No drivers found online and available for order ${orderId}`);
      return;
    }

    const matchedDrivers = availableDrivers
      .map(driver => ({
        ...driver,
        distance: this.calculateDistance(
          order.pickupLat,
          order.pickupLng,
          driver.latitude || 0,
          driver.longitude || 0,
        ),
      }))
      .sort((a, b) => a.distance - b.distance);

    const bestDriver = matchedDrivers[0];
    console.log(`Best driver found: ${bestDriver.userId} at distance ${bestDriver.distance}km`);

    try {
      this.ordersGateway.emitOrderRequest(bestDriver.userId, {
        orderId: order.id,
        trackingId: order.trackingId,
        pickupLat: order.pickupLat,
        pickupLng: order.pickupLng,
        dropLat: order.dropLat,
        dropLng: order.dropLng,
        price: order.price,
        pickupAddress: order.pickupAddress,
        dropoffAddress: order.dropoffAddress,
        recipientName: order.recipientName,
        itemType: order.itemType,
        quotedDistanceKm: order.quotedDistanceKm,
        quotedDurationMinutes: order.quotedDurationMinutes,
        customer: {
          id: order.customerId,
        },
        driverCandidate: {
          id: bestDriver.id,
          userId: bestDriver.userId,
          name: bestDriver.user?.name,
          phone: bestDriver.user?.phone,
          distanceKm: this.roundMoney(bestDriver.distance),
        },
      });
      console.log(`Notified driver ${bestDriver.userId} about order ${orderId}`);
    } catch (error) {
      console.error(`Failed to emit order request to driver ${bestDriver.userId}:`, error);
    }
  }

  async rejectOrder(orderId: string, userId: string) {
    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        rejectedBy: { push: userId },
      },
    });

    await this.matchClosestDriver(orderId);
    return { success: true };
  }

  async getAvailableOrders() {
    return this.prisma.order.findMany({
      where: {
        status: OrderStatus.REQUESTED,
      },
      include: {
        customer: { select: { id: true, name: true, phone: true, email: true } },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async acceptOrder(orderId: string, driverId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.status !== OrderStatus.REQUESTED) {
      throw new BadRequestException('Order is no longer available');
    }

    const driver = await this.prisma.driver.findUnique({
      where: { userId: driverId },
    });
    if (!driver) throw new NotFoundException('Driver not found');
    if (!driver.isOnline || driver.status === DriverStatus.OFFLINE) {
      throw new BadRequestException('Driver must be online to accept orders');
    }

    if (driver.status !== DriverStatus.AVAILABLE) {
      const routeMatched = await this.canAcceptRouteMatchedJob(driver.id, order);
      if (!routeMatched) {
        throw new BadRequestException('Driver can only accept another job when it matches the active route');
      }
    }

    const updatedOrder = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.ACCEPTED,
        driverId: driver.id,
        driverAcceptedAt: new Date(),
      },
      include: {
        driver: { include: { user: true } },
        customer: true,
      },
    });

    await this.prisma.driver.update({
      where: { id: driver.id },
      data: { status: DriverStatus.BUSY, lastActiveAt: new Date() },
    });

    this.ordersGateway.emitOrderUpdate(orderId, OrderStatus.ACCEPTED, {
      driver: updatedOrder.driver,
    });

    return updatedOrder;
  }

  async updateStatus(orderId: string, status: OrderStatus, proofOfDelivery?: string, verificationCode?: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');
    this.assertStatusTransition(order.status, status);

    if (status === OrderStatus.EN_ROUTE && order.pickupCode && verificationCode !== order.pickupCode) {
      throw new BadRequestException('Invalid pickup verification code');
    }

    if (status === OrderStatus.COMPLETED) {
      if (order.dropoffCode && verificationCode !== order.dropoffCode) {
        throw new BadRequestException('Invalid dropoff verification code');
      }
      if (!proofOfDelivery && !order.proofOfDelivery) {
        throw new BadRequestException('Proof of delivery is required to complete this order');
      }
    }

    const timestampData =
      status === OrderStatus.PICKING_UP
        ? { pickedUpAt: new Date() }
        : status === OrderStatus.COMPLETED
          ? { deliveredAt: new Date() }
          : {};

    const updatedOrder = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status,
        proofOfDelivery: proofOfDelivery || order.proofOfDelivery,
        ...timestampData,
      },
      include: {
        driver: { include: { user: true } },
        customer: true,
      },
    });

    if (status === OrderStatus.COMPLETED && updatedOrder.driverId) {
      const driverEarnings = updatedOrder.price * 0.8;
      const driverUserId = updatedOrder.driver!.userId;

      const wallet = await this.walletService.findOrCreateWallet(driverUserId, 'DRIVER');
      await this.walletService.credit(wallet.id, driverEarnings, 'RIDE_PAYMENT', orderId, {
        orderId: updatedOrder.id,
        totalPrice: updatedOrder.price,
      });

      const activeJobs = await this.countActiveDriverOrders(updatedOrder.driverId);
      await this.prisma.driver.update({
        where: { id: updatedOrder.driverId },
        data: { status: activeJobs > 0 ? DriverStatus.ON_DELIVERY : DriverStatus.AVAILABLE },
      });
    }

    if (status === OrderStatus.EN_ROUTE && updatedOrder.driverId) {
      await this.prisma.driver.update({
        where: { id: updatedOrder.driverId },
        data: { status: DriverStatus.ON_DELIVERY, lastActiveAt: new Date() },
      });
    }

    this.ordersGateway.emitOrderUpdate(orderId, status, { proofOfDelivery });

    return updatedOrder;
  }

  async cancelOrder(orderId: string, userId: string, reason: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');
    if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELLED) {
      throw new BadRequestException(`Cannot cancel an order that is already ${order.status}`);
    }

    const updatedOrder = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.CANCELLED,
        cancelledById: userId,
        cancelReason: reason,
        cancelStage: order.status,
        cancelledAt: new Date(),
      },
    });

    if (order.driverId) {
      const driver = await this.prisma.driver.findUnique({
        where: { id: order.driverId },
      });
      const activeJobs = await this.countActiveDriverOrders(order.driverId);

      await this.prisma.driver.update({
        where: { id: order.driverId },
        data: { status: activeJobs > 0 ? DriverStatus.ON_DELIVERY : DriverStatus.AVAILABLE },
      });

      if (driver?.userId === userId && order.status !== OrderStatus.REQUESTED) {
        await this.createDriverFraudSignal(
          userId,
          'Driver accepted customer contact then cancelled the delivery',
          15,
        );
      }
    }

    this.ordersGateway.emitOrderUpdate(orderId, OrderStatus.CANCELLED, { reason });
    return updatedOrder;
  }

  async getAllOrders() {
    return this.prisma.order.findMany({
      include: {
        customer: { select: { id: true, name: true, phone: true, email: true } },
        driver: { include: { user: { select: { id: true, name: true, phone: true, email: true } } } },
        cancelledBy: { select: { id: true, name: true, phone: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getOrderById(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        customer: { select: { id: true, name: true, phone: true, email: true } },
        driver: { include: { user: { select: { id: true, name: true, phone: true, email: true } } } },
        cancelledBy: { select: { id: true, name: true, phone: true, email: true } },
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async getCancelledOrders() {
    return this.prisma.order.findMany({
      where: { status: OrderStatus.CANCELLED },
      include: {
        customer: { select: { id: true, name: true, phone: true, email: true } },
        driver: { include: { user: { select: { id: true, name: true, phone: true, email: true } } } },
        cancelledBy: { select: { id: true, name: true, phone: true, email: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getOrderByTrackingId(trackingId: string) {
    const order = await this.prisma.order.findFirst({
      where: { trackingId },
      include: {
        customer: { select: { id: true, name: true, phone: true } },
        driver: { select: { id: true, latitude: true, longitude: true, user: { select: { id: true, name: true, phone: true } } } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async getDriverOrders(userId: string) {
    return this.prisma.order.findMany({
      where: {
        driver: { userId },
      },
      include: {
        customer: { select: { id: true, name: true, phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getCustomerOrders(customerId: string) {
    return this.prisma.order.findMany({
      where: { customerId },
      include: {
        driver: { include: { user: { select: { id: true, name: true, phone: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async rateOrder(orderId: string, customerId: string, rating: number, comment?: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { driver: true },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== customerId) throw new BadRequestException('Not authorized to rate this order');
    if (order.status !== OrderStatus.COMPLETED) throw new BadRequestException('Can only rate completed orders');
    if (!order.driverId) throw new BadRequestException('No driver assigned to this order');

    await this.prisma.order.update({
      where: { id: orderId },
      data: { rating, ratingComment: comment },
    });

    const driver = await this.prisma.driver.findUnique({
      where: { id: order.driverId },
    });

    if (!driver) throw new BadRequestException('Driver not found');

    const newTotalRatings = driver.totalRatings + 1;
    const newAverageRating = (driver.averageRating * driver.totalRatings + rating) / newTotalRatings;

    await this.prisma.driver.update({
      where: { id: order.driverId },
      data: {
        totalRatings: newTotalRatings,
        averageRating: parseFloat(newAverageRating.toFixed(2)),
      },
    });

    return { success: true, averageRating: newAverageRating };
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

  private roundMoney(value: number) {
    return Math.round(value * 100) / 100;
  }

  private async countActiveDriverOrders(driverId: string) {
    return this.prisma.order.count({
      where: {
        driverId,
        status: {
          in: [
            OrderStatus.ACCEPTED,
            OrderStatus.PICKING_UP,
            OrderStatus.EN_ROUTE,
            OrderStatus.DESTINATION_REACHED,
          ],
        },
      },
    });
  }

  private async canAcceptRouteMatchedJob(driverId: string, order: { pickupLat: number; pickupLng: number; dropLat: number; dropLng: number }) {
    const activeOrders = await this.prisma.order.findMany({
      where: {
        driverId,
        status: {
          in: [OrderStatus.ACCEPTED, OrderStatus.PICKING_UP, OrderStatus.EN_ROUTE],
        },
      },
      select: { pickupLat: true, pickupLng: true, dropLat: true, dropLng: true },
    });

    if (activeOrders.length === 0) return true;
    if (activeOrders.length >= 3) return false;

    return activeOrders.some((activeOrder) => {
      const pickupDistance = this.calculateDistance(
        activeOrder.pickupLat,
        activeOrder.pickupLng,
        order.pickupLat,
        order.pickupLng,
      );
      const dropoffDistance = this.calculateDistance(
        activeOrder.dropLat,
        activeOrder.dropLng,
        order.dropLat,
        order.dropLng,
      );

      return pickupDistance <= 8 && dropoffDistance <= 12;
    });
  }

  private async createDriverFraudSignal(userId: string, reason: string, scoreIncrease: number) {
    const wallet = await this.prisma.wallet.upsert({
      where: { userId },
      update: {},
      create: { userId, type: WalletType.DRIVER },
    });

    await this.prisma.$transaction([
      this.prisma.driver.update({
        where: { userId },
        data: { fraudScore: { increment: scoreIncrease } },
      }),
      this.prisma.fraudLog.create({
        data: { walletId: wallet.id, reason },
      }),
    ]);
  }

  private generateVerificationCode() {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  private async generateTrackingId() {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const candidate = `RID-${Date.now().toString(36).toUpperCase()}-${Math.random()
        .toString(36)
        .substring(2, 6)
        .toUpperCase()}`;
      const existing = await this.prisma.order.findUnique({ where: { trackingId: candidate } });
      if (!existing) return candidate;
    }

    throw new BadRequestException('Could not generate tracking ID');
  }

  private assertStatusTransition(from: OrderStatus, to: OrderStatus) {
    const allowed: Record<OrderStatus, OrderStatus[]> = {
      REQUESTED: [OrderStatus.ACCEPTED, OrderStatus.CANCELLED],
      ACCEPTED: [OrderStatus.PICKING_UP, OrderStatus.CANCELLED],
      PICKING_UP: [OrderStatus.EN_ROUTE, OrderStatus.CANCELLED],
      EN_ROUTE: [OrderStatus.DESTINATION_REACHED, OrderStatus.CANCELLED],
      DESTINATION_REACHED: [OrderStatus.COMPLETED, OrderStatus.CANCELLED],
      COMPLETED: [],
      CANCELLED: [],
    };

    if (!allowed[from].includes(to)) {
      throw new BadRequestException(`Invalid order status change from ${from} to ${to}`);
    }
  }
}
