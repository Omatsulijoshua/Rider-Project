import { driverEarningsReport, revenueReport } from "@/lib/mock-data";
import type { ApiResponse } from "@/types/api";

export async function getRevenueReport() {
  return Promise.resolve<ApiResponse<typeof revenueReport>>({ data: revenueReport });
}

export async function getDriverEarningsReport() {
  return Promise.resolve<ApiResponse<typeof driverEarningsReport>>({
    data: driverEarningsReport,
  });
}
