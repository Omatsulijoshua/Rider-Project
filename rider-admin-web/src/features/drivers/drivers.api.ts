import { drivers } from "@/lib/mock-data";
import type { ApiResponse } from "@/types/api";

export async function getDrivers() {
  return Promise.resolve<ApiResponse<typeof drivers>>({ data: drivers });
}

export async function getPendingKYC() {
  return Promise.resolve<ApiResponse<typeof drivers>>({
    data: drivers.filter((driver) => driver.kycStatus === "pending"),
  });
}
