import { customers } from "@/lib/mock-data";
import type { ApiResponse, PaginatedResponse } from "@/types/api";
import type { Customer } from "@/types/user";

export async function getCustomers(params: { page: number; limit: number }) {
  return Promise.resolve<ApiResponse<PaginatedResponse<Customer>>>({
    data: {
      items: customers,
      page: params.page,
      limit: params.limit,
      total: customers.length,
    },
  });
}
