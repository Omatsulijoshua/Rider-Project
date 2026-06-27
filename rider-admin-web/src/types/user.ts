export type UserStatus = "active" | "flagged" | "new";

export type Customer = {
  id: string;
  name: string;
  email: string;
  phone: string;
  city: string;
  totalTrips: number;
  lifetimeSpend: number;
  status: UserStatus;
  joinedAt: string;
};

export type AdminUser = {
  id: string;
  name: string;
  role: string;
  shift: string;
  status: "online" | "offline";
};
