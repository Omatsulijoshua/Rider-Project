import type { Driver } from "@/types/driver";
import type { Ride } from "@/types/ride";
import type { AdminUser, Customer } from "@/types/user";
import type { Wallet, WalletTransaction } from "@/types/wallet";

export type MetricCard = {
  id: string;
  label: string;
  value: number;
  delta: number;
  suffix?: string;
};

export type TrendPoint = {
  label: string;
  value: number;
};

export type PayoutRequest = {
  id: string;
  driver: string;
  amount: number;
  bank: string;
  requestedAt: string;
  status: "queued" | "approved" | "failed";
};

export type FraudAlert = {
  id: string;
  subject: string;
  score: number;
  rule: string;
  city: string;
  status: "open" | "reviewing" | "resolved";
};

export type FraudRule = {
  id: string;
  name: string;
  sensitivity: "low" | "medium" | "high";
  action: string;
  hitRate: number;
};

export type ReportRow = {
  label: string;
  primary: number;
  secondary: number;
};

export type FreezeCase = {
  id: string;
  owner: string;
  reason: string;
  amount: number;
  state: "temporary" | "investigating";
};

export const metricCards: MetricCard[] = [
  { id: "gross", label: "Gross revenue", value: 18450000, delta: 14.2 },
  { id: "rides", label: "Completed rides", value: 12480, delta: 8.6 },
  { id: "drivers", label: "Active drivers", value: 842, delta: 5.1 },
  { id: "wallets", label: "Wallet float", value: 6320000, delta: -1.4 },
];

export const earningsTrend: TrendPoint[] = [
  { label: "Mon", value: 2100000 },
  { label: "Tue", value: 2450000 },
  { label: "Wed", value: 2280000 },
  { label: "Thu", value: 2660000 },
  { label: "Fri", value: 3010000 },
  { label: "Sat", value: 3470000 },
  { label: "Sun", value: 2980000 },
];

export const tripTrend: TrendPoint[] = [
  { label: "06:00", value: 86 },
  { label: "09:00", value: 214 },
  { label: "12:00", value: 176 },
  { label: "15:00", value: 241 },
  { label: "18:00", value: 312 },
  { label: "21:00", value: 190 },
];

export const walletFlowTrend: TrendPoint[] = [
  { label: "Week 1", value: 920000 },
  { label: "Week 2", value: 1180000 },
  { label: "Week 3", value: 1030000 },
  { label: "Week 4", value: 1310000 },
];

export const customers: Customer[] = [
  {
    id: "CUS-102",
    name: "Ada Nnadi",
    email: "ada@riderhq.africa",
    phone: "+234 801 200 1002",
    city: "Lagos",
    totalTrips: 118,
    lifetimeSpend: 468000,
    status: "active",
    joinedAt: "2025-11-18T08:30:00Z",
  },
  {
    id: "CUS-128",
    name: "Tunde Bakare",
    email: "tunde@riderhq.africa",
    phone: "+234 803 880 0194",
    city: "Abuja",
    totalTrips: 42,
    lifetimeSpend: 186000,
    status: "flagged",
    joinedAt: "2026-01-05T10:00:00Z",
  },
  {
    id: "CUS-146",
    name: "Miriam Jide",
    email: "miriam@riderhq.africa",
    phone: "+234 809 310 4421",
    city: "Port Harcourt",
    totalTrips: 7,
    lifetimeSpend: 28100,
    status: "new",
    joinedAt: "2026-04-02T09:18:00Z",
  },
];

export const drivers: Driver[] = [
  {
    id: "DRV-204",
    name: "Femi Lawal",
    city: "Lagos",
    vehicle: "Toyota Camry",
    rating: 4.9,
    acceptanceRate: 94,
    earningsToday: 38400,
    walletBalance: 116000,
    status: "online",
    kycStatus: "approved",
  },
  {
    id: "DRV-287",
    name: "Grace Obi",
    city: "Abuja",
    vehicle: "Honda Accord",
    rating: 4.7,
    acceptanceRate: 88,
    earningsToday: 27900,
    walletBalance: 62500,
    status: "offline",
    kycStatus: "pending",
  },
  {
    id: "DRV-301",
    name: "Kabiru Musa",
    city: "Kano",
    vehicle: "Hyundai Sonata",
    rating: 4.2,
    acceptanceRate: 76,
    earningsToday: 12300,
    walletBalance: 15400,
    status: "suspended",
    kycStatus: "rejected",
  },
];

export const rides: Ride[] = [
  {
    id: "RID-781",
    rider: "Ada Nnadi",
    driver: "Femi Lawal",
    pickup: "Lekki Phase 1",
    destination: "Victoria Island",
    fare: 12500,
    distanceKm: 14.6,
    status: "completed",
    startedAt: "2026-04-11T07:20:00Z",
  },
  {
    id: "RID-784",
    rider: "Tunde Bakare",
    driver: "Grace Obi",
    pickup: "Wuse 2",
    destination: "Garki",
    fare: 8400,
    distanceKm: 10.4,
    status: "disputed",
    startedAt: "2026-04-11T08:10:00Z",
  },
  {
    id: "RID-790",
    rider: "Miriam Jide",
    driver: "Kabiru Musa",
    pickup: "GRA",
    destination: "Ada George",
    fare: 6900,
    distanceKm: 8.1,
    status: "cancelled",
    startedAt: "2026-04-11T09:05:00Z",
  },
];

export const wallets: Wallet[] = [
  {
    owner: "Driver settlement pool",
    balance: 2180000,
    pendingPayout: 864000,
    lastSettlement: "2026-04-10T19:20:00Z",
    status: "healthy",
  },
  {
    owner: "Rider promo wallet",
    balance: 590000,
    pendingPayout: 0,
    lastSettlement: "2026-04-10T15:05:00Z",
    status: "review",
  },
  {
    owner: "Risk hold reserve",
    balance: 320000,
    pendingPayout: 112000,
    lastSettlement: "2026-04-09T11:40:00Z",
    status: "frozen",
  },
];

export const walletTransactions: WalletTransaction[] = [
  {
    id: "WTX-12",
    actor: "Femi Lawal",
    type: "credit",
    amount: 21400,
    createdAt: "2026-04-11T08:20:00Z",
    status: "success",
  },
  {
    id: "WTX-13",
    actor: "Grace Obi",
    type: "hold",
    amount: 4800,
    createdAt: "2026-04-11T08:28:00Z",
    status: "pending",
  },
  {
    id: "WTX-14",
    actor: "Kabiru Musa",
    type: "debit",
    amount: 11000,
    createdAt: "2026-04-11T08:44:00Z",
    status: "reversed",
  },
];

export const payoutRequests: PayoutRequest[] = [
  {
    id: "PAY-900",
    driver: "Femi Lawal",
    amount: 80000,
    bank: "Kuda",
    requestedAt: "2026-04-11T07:12:00Z",
    status: "queued",
  },
  {
    id: "PAY-901",
    driver: "Grace Obi",
    amount: 56000,
    bank: "GTBank",
    requestedAt: "2026-04-11T06:45:00Z",
    status: "approved",
  },
  {
    id: "PAY-902",
    driver: "Kabiru Musa",
    amount: 24000,
    bank: "Zenith",
    requestedAt: "2026-04-11T05:51:00Z",
    status: "failed",
  },
];

export const fraudAlerts: FraudAlert[] = [
  {
    id: "FRA-31",
    subject: "Duplicate device wallet hop",
    score: 92,
    rule: "Wallet velocity",
    city: "Lagos",
    status: "open",
  },
  {
    id: "FRA-32",
    subject: "Trip spoof cluster",
    score: 81,
    rule: "Geo mismatch",
    city: "Abuja",
    status: "reviewing",
  },
  {
    id: "FRA-33",
    subject: "Fare inflation attempt",
    score: 67,
    rule: "Distance anomaly",
    city: "Port Harcourt",
    status: "resolved",
  },
];

export const fraudRules: FraudRule[] = [
  { id: "RULE-1", name: "Wallet velocity", sensitivity: "high", action: "Freeze payouts", hitRate: 12.4 },
  { id: "RULE-2", name: "GPS drift mismatch", sensitivity: "medium", action: "Queue review", hitRate: 8.1 },
  { id: "RULE-3", name: "Referral ring detector", sensitivity: "low", action: "Shadow monitor", hitRate: 3.8 },
];

export const revenueReport: ReportRow[] = [
  { label: "Lagos", primary: 9800000, secondary: 6420 },
  { label: "Abuja", primary: 4650000, secondary: 3120 },
  { label: "Port Harcourt", primary: 2310000, secondary: 1460 },
];

export const driverEarningsReport: ReportRow[] = [
  { label: "Top 10%", primary: 142000, secondary: 46 },
  { label: "Middle 40%", primary: 71000, secondary: 212 },
  { label: "Long tail", primary: 28400, secondary: 584 },
];

export const freezeCases: FreezeCase[] = [
  { id: "FRZ-11", owner: "Risk hold reserve", reason: "Chargeback investigation", amount: 112000, state: "investigating" },
  { id: "FRZ-12", owner: "Promo abuse hold", reason: "Referral pattern spike", amount: 68000, state: "temporary" },
];

export const adminUsers: AdminUser[] = [
  { id: "ADM-1", name: "Mercy Ayo", role: "Super Admin", shift: "08:00 - 16:00", status: "online" },
  { id: "ADM-2", name: "Sodiq Hassan", role: "Finance", shift: "09:00 - 17:00", status: "online" },
  { id: "ADM-3", name: "Ruth Opara", role: "Support", shift: "12:00 - 20:00", status: "offline" },
];
