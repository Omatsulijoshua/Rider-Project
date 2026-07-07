import { NextRequest, NextResponse } from "next/server";

const backendBaseUrl = process.env.BACKEND_API_URL ?? "https://rider-project.onrender.com";

async function fetchJson(path: string, token?: string) {
  const response = await fetch(`${backendBaseUrl}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(await response.text());
  }

  return response.json();
}

function startOfMonth(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function endOfMonth(date: Date) {
  return new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);
}

export async function GET(request: NextRequest) {
  const token = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");

  if (!token) {
    return NextResponse.json({ message: "Missing authorization token." }, { status: 401 });
  }

  try {
    const now = new Date();
    const revenueRequests = Array.from({ length: 6 }).map((_, index) => {
      const monthDate = new Date(now.getFullYear(), now.getMonth() - (5 - index), 1);
      const from = startOfMonth(monthDate).toISOString();
      const to = endOfMonth(monthDate).toISOString();
      const label = monthDate.toLocaleDateString("en-NG", { month: "short" });

      return fetchJson(
        `/admin/dashboard/revenue?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`,
        token,
      ).then((result) => ({ label, value: Number(result?._sum?.amount ?? 0) }));
    });

    const [summary, users, orders, kycs, revenueTrend] = await Promise.all([
      fetchJson("/admin/dashboard/summary", token),
      fetchJson("/users", token),
      fetchJson("/orders/all", token),
      fetchJson("/kyc/all", token),
      Promise.all(revenueRequests),
    ]);

    const customers = users
      .filter((user: { role: string }) => user.role === "CUSTOMER")
      .map((user: { id: string; email?: string; phone: string; status: string; createdAt: string }) => {
        const customerOrders = orders.filter(
          (order: { customerId: string }) => order.customerId === user.id,
        );

        return {
          id: user.id,
          email: user.email ?? null,
          phone: user.phone,
          status: user.status,
          createdAt: user.createdAt,
          totalOrders: customerOrders.length,
          totalSpend: customerOrders.reduce(
            (sum: number, order: { price: number }) => sum + Number(order.price ?? 0),
            0,
          ),
        };
      });

    const drivers = users
      .filter((user: { role: string }) => user.role === "DRIVER")
      .map((user: { id: string; email?: string; phone: string; status: string; createdAt: string }) => ({
        id: user.id,
        userId: user.id,
        phone: user.phone,
        email: user.email ?? null,
        status: user.status,
        isOnline: false,
        createdAt: user.createdAt,
        walletBalance: 0,
        totalOrders: orders.filter(
          (order: { driver?: { userId?: string } | null }) => order.driver?.userId === user.id,
        ).length,
      }));

    const rides = orders.map(
      (order: {
        id: string;
        status: string;
        price: number;
        createdAt: string;
        customer?: { phone: string; email?: string | null };
        driver?: { userId?: string | null } | null;
        pickupLat: number;
        pickupLng: number;
        dropLat: number;
        dropLng: number;
        cancelReason?: string | null;
      }) => ({
        id: order.id,
        status: order.status,
        price: Number(order.price ?? 0),
        createdAt: order.createdAt,
        customerPhone: order.customer?.phone ?? "Unknown",
        customerEmail: order.customer?.email ?? null,
        driverPhone: order.driver?.userId ?? null,
        pickup: { lat: order.pickupLat, lng: order.pickupLng },
        dropoff: { lat: order.dropLat, lng: order.dropLng },
        cancelReason: order.cancelReason ?? null,
      }),
    );

    const pendingKyc = kycs.filter((kyc: { status: string }) => kyc.status === "PENDING").length;

    const ordersByStatusMap: Record<string, number> = rides.reduce(
      (accumulator: Record<string, number>, ride: { status: string }) => {
        accumulator[ride.status] = (accumulator[ride.status] ?? 0) + 1;
        return accumulator;
      },
      {},
    );

    const usersByStatusMap: Record<string, number> = users.reduce(
      (accumulator: Record<string, number>, user: { status: string }) => {
        accumulator[user.status] = (accumulator[user.status] ?? 0) + 1;
        return accumulator;
      },
      {},
    );

    const response = {
      summary: {
        platformBalance: Number(summary.platformBalance ?? 0),
        driverHoldings: Number(summary.driverHoldings?._sum?.balance ?? 0),
        totalCustomers: customers.length,
        totalDrivers: drivers.length,
        totalOrders: rides.length,
        completedOrdersToday: rides.filter((ride: { status: string }) => ride.status === "DELIVERED").length,
        pendingKyc,
        pendingWithdrawals: 0,
      },
      revenueTrend,
      customers,
      drivers,
      rides,
      wallets: [],
      payouts: [],
      fraudAlerts: [],
      reports: {
        ordersByStatus: Object.entries(ordersByStatusMap).map(([label, value]) => ({ label, value })),
        usersByStatus: Object.entries(usersByStatusMap).map(([label, value]) => ({ label, value })),
      },
      adminUsers: users
        .filter((user: { role: string }) => user.role === "ADMIN")
        .map((user: { id: string; email?: string; phone: string; status: string; createdAt: string }) => ({
          id: user.id,
          phone: user.phone,
          email: user.email ?? null,
          status: user.status,
          createdAt: user.createdAt,
        })),
    };

    return NextResponse.json(response);
  } catch (error) {
    return NextResponse.json(
      {
        message: error instanceof Error ? error.message : "Unable to load backend console data.",
      },
      { status: 500 },
    );
  }
}
