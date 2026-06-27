export type KycStatus = "approved" | "pending" | "rejected";

export type Driver = {
  id: string;
  name: string;
  city: string;
  vehicle: string;
  rating: number;
  acceptanceRate: number;
  earningsToday: number;
  walletBalance: number;
  status: "online" | "offline" | "suspended";
  kycStatus: KycStatus;
};
