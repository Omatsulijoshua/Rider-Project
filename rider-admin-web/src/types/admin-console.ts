export type AdminConsolePoint = {
  label: string;
  value: number;
};

export type AdminConsoleSummary = {
  platformBalance: number;
  driverHoldings: number;
  totalCustomers: number;
  totalDrivers: number;
  totalOrders: number;
  totalB2BVolume: number;
  activeDriversCount: number;
  completedOrdersToday: number;
  pendingKyc: number;
  pendingWithdrawals: number;
};

export type AdminConsoleCustomer = {
  id: string;
  email: string | null;
  phone: string;
  status: string;
  createdAt: string;
  totalOrders: number;
  totalSpend: number;
};

export type AdminConsoleDriver = {
  id: string;
  userId: string;
  phone: string;
  email: string | null;
  status: string;
  isOnline: boolean;
  createdAt: string;
  walletBalance: number;
  totalOrders: number;
};

export type AdminConsoleRide = {
  id: string;
  status: string;
  price: number;
  createdAt: string;
  customerPhone: string;
  customerEmail: string | null;
  driverPhone: string | null;
  pickup: { lat: number; lng: number };
  dropoff: { lat: number; lng: number };
  cancelReason: string | null;
};

export type AdminConsoleWallet = {
  id: string;
  ownerPhone: string | null;
  ownerEmail: string | null;
  type: string;
  balance: number;
  frozen: boolean;
  createdAt: string;
  withdrawalCount: number;
};

export type AdminConsolePayout = {
  id: string;
  driverId: string;
  walletId: string;
  amount: number;
  status: string;
  reason: string | null;
  createdAt: string;
  updatedAt: string;
};

export type AdminConsoleFraudAlert = {
  id: string;
  walletId: string;
  reason: string;
  resolved: boolean;
  createdAt: string;
  ownerPhone: string | null;
  ownerEmail: string | null;
};

export type AdminConsoleAdminUser = {
  id: string;
  phone: string;
  email: string | null;
  status: string;
  createdAt: string;
};

export type AdminConsoleData = {
  summary: AdminConsoleSummary;
  revenueTrend: AdminConsolePoint[];
  customers: AdminConsoleCustomer[];
  drivers: AdminConsoleDriver[];
  rides: AdminConsoleRide[];
  wallets: AdminConsoleWallet[];
  payouts: AdminConsolePayout[];
  fraudAlerts: AdminConsoleFraudAlert[];
  reports: {
    ordersByStatus: AdminConsolePoint[];
    usersByStatus: AdminConsolePoint[];
  };
  adminUsers: AdminConsoleAdminUser[];
};
