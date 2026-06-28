import { Injectable, NotFoundException } from '@nestjs/common';
import { DriverStatus, OrderStatus, WalletType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DriversService {
  constructor(private prisma: PrismaService) {}

  async updateLocation(userId: string, lat: number, lng: number) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver not found');
    if (!driver.isOnline) return driver;

    return this.prisma.driver.update({
      where: { userId },
      data: {
        latitude: lat,
        longitude: lng,
        lastActiveAt: new Date(),
        locationDisabledAt: null,
      },
      include: { user: true },
    });
  }

  async getDriverByUserId(userId: string) {
    return this.prisma.driver.findUnique({
      where: { userId },
      include: { user: true },
    });
  }

  async updateStatus(userId: string, isOnline: boolean) {
    const existingDriver = await this.prisma.driver.findUnique({ where: { userId } });
    const activeDelivery = existingDriver ? await this.hasActiveDelivery(existingDriver.id) : false;
    const status = isOnline
      ? activeDelivery
        ? DriverStatus.ON_DELIVERY
        : DriverStatus.AVAILABLE
      : DriverStatus.OFFLINE;

    const driver = await this.prisma.driver.upsert({
      where: { userId },
      update: {
        isOnline,
        status,
        lastActiveAt: new Date(),
      },
      create: {
        userId,
        isOnline,
        status,
        lastActiveAt: new Date(),
      },
      include: { user: true },
    });

    if (!isOnline && activeDelivery) {
      await this.createDriverSafetyAlert(
        userId,
        'Driver went offline during an active delivery',
        20,
      );
    }

    return driver;
  }

  async markLocationDisabled(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver not found');

    const activeDelivery = await this.hasActiveDelivery(driver.id);
    const updatedDriver = await this.prisma.driver.update({
      where: { userId },
      data: {
        locationDisabledAt: new Date(),
        lastActiveAt: new Date(),
      },
      include: { user: true },
    });

    if (activeDelivery) {
      await this.createDriverSafetyAlert(
        userId,
        'Driver disabled location while holding a package',
        30,
      );
    }

    return updatedDriver;
  }

  async getNearbyAvailableDrivers(lat: number, lng: number, radiusKm = 10, vehicleType?: string) {
    const drivers = await this.prisma.driver.findMany({
      where: {
        isOnline: true,
        status: DriverStatus.AVAILABLE,
        latitude: { not: null },
        longitude: { not: null },
        ...(vehicleType ? { vehicleType } : {}),
      },
      include: { user: { select: { id: true, name: true, phone: true } } },
    });

    return drivers
      .map((driver) => ({
        id: driver.id,
        userId: driver.userId,
        name: driver.user.name,
        phone: driver.user.phone,
        status: driver.status,
        isOnline: driver.isOnline,
        vehicleType: driver.vehicleType ?? 'bike',
        rating: driver.averageRating,
        completedJobs: driver.totalRatings,
        lat: driver.latitude,
        lng: driver.longitude,
        lastActiveAt: driver.lastActiveAt,
        distanceKm: this.roundDistance(
          this.calculateDistance(lat, lng, driver.latitude ?? 0, driver.longitude ?? 0),
        ),
      }))
      .filter((driver) => driver.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

  async getAdminDriverMap(filters: {
    vehicleType?: string;
    status?: DriverStatus;
    minRating?: number;
    activeDelivery?: boolean;
  }) {
    const drivers = await this.prisma.driver.findMany({
      where: {
        latitude: { not: null },
        longitude: { not: null },
        ...(filters.vehicleType ? { vehicleType: filters.vehicleType } : {}),
        ...(filters.status ? { status: filters.status } : {}),
        ...(filters.minRating ? { averageRating: { gte: filters.minRating } } : {}),
      },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        orders: {
          where: {
            status: {
              in: [
                OrderStatus.ACCEPTED,
                OrderStatus.PICKING_UP,
                OrderStatus.EN_ROUTE,
                OrderStatus.DESTINATION_REACHED,
              ],
            },
          },
          select: { id: true, trackingId: true, status: true },
        },
      },
      orderBy: { lastActiveAt: 'desc' },
    });

    return drivers
      .filter((driver) =>
        filters.activeDelivery === undefined
          ? true
          : filters.activeDelivery
            ? driver.orders.length > 0
            : driver.orders.length === 0,
      )
      .map((driver) => ({
        id: driver.id,
        userId: driver.userId,
        name: driver.user.name,
        phone: driver.user.phone,
        email: driver.user.email,
        isOnline: driver.isOnline,
        status: driver.status,
        vehicleType: driver.vehicleType ?? 'bike',
        rating: driver.averageRating,
        completedJobs: driver.totalRatings,
        fraudScore: driver.fraudScore,
        lat: driver.latitude,
        lng: driver.longitude,
        lastActiveAt: driver.lastActiveAt,
        activeDeliveries: driver.orders,
      }));
  }

  async createDriverSafetyAlert(userId: string, reason: string, scoreIncrease = 10) {
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
        data: {
          walletId: wallet.id,
          reason,
        },
      }),
    ]);
  }

  private async hasActiveDelivery(driverId: string) {
    const activeOrders = await this.prisma.order.count({
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

    return activeOrders > 0;
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

  private roundDistance(value: number) {
    return Math.round(value * 100) / 100;
  }
}
