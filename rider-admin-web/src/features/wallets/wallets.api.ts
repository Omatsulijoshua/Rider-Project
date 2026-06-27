import { freezeCases, walletTransactions, wallets } from "@/lib/mock-data";
import type { ApiResponse } from "@/types/api";

export async function getWalletOverview() {
  return Promise.resolve<ApiResponse<typeof wallets>>({ data: wallets });
}

export async function getWalletTransactions() {
  return Promise.resolve<ApiResponse<typeof walletTransactions>>({
    data: walletTransactions,
  });
}

export async function getFreezeCases() {
  return Promise.resolve<ApiResponse<typeof freezeCases>>({ data: freezeCases });
}
