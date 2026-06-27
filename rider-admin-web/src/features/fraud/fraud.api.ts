import { fraudAlerts, fraudRules } from "@/lib/mock-data";
import type { ApiResponse } from "@/types/api";

export async function getFraudAlerts() {
  return Promise.resolve<ApiResponse<typeof fraudAlerts>>({ data: fraudAlerts });
}

export async function getFraudRules() {
  return Promise.resolve<ApiResponse<typeof fraudRules>>({ data: fraudRules });
}
