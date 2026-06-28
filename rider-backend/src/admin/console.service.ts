import { Injectable } from '@nestjs/common';
import { OrderStatus, UserRole, UserStatus, WalletType, WithdrawalStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminConsoleService {
  constructor(private readonly prisma: PrismaService) {}

  async getConsoleData() {
    const [users, drivers, orders, wallets, kycs, withdrawals, fraudLogs, admins] =
      await Promise.all([
        this.prisma.user.findMany({ orderBy: { createdAt: 'desc' } }),
        this.prisma.driver.findMany({ include: { user: true }, orderBy: { createdAt: 'desc' } }),
        this.prisma.order.findMany({
          include: { customer: true, driver: { include: { user: true } }, cancelledBy: true },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.wallet.findMany({ include: { user: true, withdrawals: true }, orderBy: { createdAt: 'desc' } }),
        this.prisma.kyc.findMany({ include: { user: true }, orderBy: { createdAt: 'desc' } }),
        this.prisma.withdrawal.findMany({ include: { wallet: true }, orderBy: { createdAt: 'desc' } }),
        this.prisma.fraudLog.findMany({ include: { wallet: { include: { user: true } } }, orderBy: { createdAt: 'desc' } }),
        this.prisma.user.findMany({ where: { role: UserRole.ADMIN }, orderBy: { createdAt: 'desc' } }),
      ]);

    const customerUsers = users.filter((user) => user.role === UserRole.CUSTOMER);
    const driverUsers = users.filter((user) => user.role === UserRole.DRIVER);
    const driverWallets = wallets.filter((wallet) => wallet.user?.role === UserRole.DRIVER);
    const totalDriverHoldings = driverWallets.reduce((sum, wallet) => sum + wallet.balance, 0);
    const platformBalance = wallets.filter((wallet) => wallet.user === null).reduce((sum, wallet) => sum + wallet.balance, 0);
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    return {
      summary: {
        platformBalance,
        driverHoldings: totalDriverHoldings,
        totalCustomers: customerUsers.length,
        totalDrivers: drivers.length,
        totalOrders: orders.length,
        totalB2BVolume: orders
          .filter((o) => o.status === OrderStatus.COMPLETED)
          .reduce((sum, o) => sum + (o.price || 0), 0),
        activeDriversCount: drivers.filter((d) => d.isOnline).length,
        completedOrdersToday: orders.filter(
          (order) => order.status === OrderStatus.COMPLETED && order.createdAt >= todayStart,
        ).length,
        pendingKyc: kycs.filter((kyc) => kyc.status === 'PENDING').length,
        pendingWithdrawals: withdrawals.filter(
          (withdrawal) => withdrawal.status === WithdrawalStatus.PENDING,
        ).length,
      },
      revenueTrend: [],
      customers: customerUsers.map((user) => ({
        id: user.id,
        email: user.email,
        phone: user.phone,
        status: user.status,
        createdAt: user.createdAt,
        totalOrders: orders.filter((order) => order.customerId === user.id).length,
        totalSpend: orders
          .filter((order) => order.customerId === user.id)
          .reduce((sum, order) => sum + order.price, 0),
      })),
      drivers: drivers.map((driver) => ({
        id: driver.id,
        userId: driver.userId,
        phone: driver.user.phone,
        email: driver.user.email,
        status: driver.user.status,
        isOnline: driver.isOnline,
        createdAt: driver.createdAt,
        walletBalance: wallets.find((wallet) => wallet.userId === driver.userId)?.balance ?? 0,
        totalOrders: orders.filter((order) => order.driverId === driver.id).length,
        driverStatus: driver.status,
        vehicleType: driver.vehicleType ?? 'bike',
        rating: driver.averageRating,
        completedJobs: driver.totalRatings,
        fraudScore: driver.fraudScore,
        latitude: driver.latitude,
        longitude: driver.longitude,
        lastActiveAt: driver.lastActiveAt,
      })),
      liveDrivers: drivers
        .filter((driver) => driver.latitude !== null && driver.longitude !== null)
        .map((driver) => {
          const activeDeliveries = orders.filter(
            (order) =>
              order.driverId === driver.id &&
              [
                OrderStatus.ACCEPTED,
                OrderStatus.PICKING_UP,
                OrderStatus.EN_ROUTE,
                OrderStatus.DESTINATION_REACHED,
              ].includes(order.status),
          );

          return {
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
            activeDeliveryCount: activeDeliveries.length,
            offlineDuringDelivery: !driver.isOnline && activeDeliveries.length > 0,
          };
        }),
      rides: orders.map((order) => ({
        id: order.id,
        status: order.status,
        price: order.price,
        createdAt: order.createdAt,
        customerPhone: order.customer.phone,
        customerEmail: order.customer.email,
        driverPhone: order.driver?.user.phone ?? null,
        pickup: { lat: order.pickupLat, lng: order.pickupLng },
        dropoff: { lat: order.dropLat, lng: order.dropLng },
        cancelReason: order.cancelReason,
      })),
      wallets: wallets.map((wallet) => ({
        id: wallet.id,
        ownerPhone: wallet.user?.phone ?? null,
        ownerEmail: wallet.user?.email ?? null,
        type: wallet.type,
        frozen: wallet.frozen,
        balance: wallet.balance,
        createdAt: wallet.createdAt,
        withdrawalCount: wallet.withdrawals.length,
      })),
      payouts: withdrawals.map((withdrawal) => ({
        id: withdrawal.id,
        driverId: withdrawal.driverId,
        walletId: withdrawal.walletId,
        amount: withdrawal.amount,
        status: withdrawal.status,
        reason: withdrawal.reason,
        createdAt: withdrawal.createdAt,
        updatedAt: withdrawal.updatedAt,
      })),
      fraudAlerts: fraudLogs.map((log) => ({
        id: log.id,
        walletId: log.walletId,
        reason: log.reason,
        resolved: log.resolved,
        createdAt: log.createdAt,
        ownerPhone: log.wallet.user?.phone ?? null,
        ownerEmail: log.wallet.user?.email ?? null,
      })),
      reports: {
        ordersByStatus: Object.values(OrderStatus).map((status) => ({
          label: status,
          value: orders.filter((order) => order.status === status).length,
        })),
        usersByStatus: Object.values(UserStatus).map((status) => ({
          label: status,
          value: users.filter((user) => user.status === status).length,
        })),
      },
      adminUsers: admins.map((admin) => ({
        id: admin.id,
        phone: admin.phone,
        email: admin.email,
        status: admin.status,
        createdAt: admin.createdAt,
      })),
    };
  }
}
