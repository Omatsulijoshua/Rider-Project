export type RouteKey =
  | "overview"
  | "customers"
  | "drivers"
  | "rides"
  | "wallets"
  | "payouts"
  | "fraud"
  | "reports"
  | "settings";

export const routes: Record<RouteKey, string> = {
  overview: "/",
  customers: "/customers",
  drivers: "/drivers",
  rides: "/rides",
  wallets: "/wallets",
  payouts: "/payouts",
  fraud: "/fraud",
  reports: "/reports",
  settings: "/settings",
};

export const routeLabels: Record<RouteKey, string> = {
  overview: "Overview",
  customers: "Customers",
  drivers: "Drivers",
  rides: "Rides",
  wallets: "Wallets",
  payouts: "Payouts",
  fraud: "Fraud",
  reports: "Reports",
  settings: "Settings",
};
