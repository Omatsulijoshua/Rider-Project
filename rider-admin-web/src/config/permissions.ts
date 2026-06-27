import type { RouteKey } from "./routes";

export type AdminRole = "super_admin" | "ops_manager" | "support" | "finance";

export const permissions: Record<AdminRole, RouteKey[]> = {
  super_admin: [
    "overview",
    "customers",
    "drivers",
    "rides",
    "wallets",
    "payouts",
    "fraud",
    "reports",
    "settings",
  ],
  ops_manager: ["overview", "customers", "drivers", "rides", "fraud", "reports"],
  support: ["overview", "customers", "drivers", "rides", "wallets"],
  finance: ["overview", "wallets", "payouts", "reports"],
};

export const canAccessRoute = (role: AdminRole, route: RouteKey) =>
  permissions[role].includes(route);
