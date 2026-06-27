import { wallets } from "@/lib/mock-data";
import type { Wallet } from "@/types/wallet";

export type WalletsState = {
  items: Wallet[];
};

export const initialWalletsState: WalletsState = {
  items: wallets,
};
