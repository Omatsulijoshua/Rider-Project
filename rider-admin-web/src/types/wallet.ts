export type WalletStatus = "healthy" | "review" | "frozen";

export type Wallet = {
  owner: string;
  balance: number;
  pendingPayout: number;
  lastSettlement: string;
  status: WalletStatus;
};

export type WalletTransaction = {
  id: string;
  actor: string;
  type: "credit" | "debit" | "hold";
  amount: number;
  createdAt: string;
  status: "success" | "pending" | "reversed";
};
