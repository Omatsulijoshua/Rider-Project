import { payoutRequests } from "@/lib/mock-data";
import type { ApiResponse } from "@/types/api";

export async function getPayoutRequests() {
  return Promise.resolve<ApiResponse<typeof payoutRequests>>({ data: payoutRequests });
}
