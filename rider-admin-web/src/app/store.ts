import { initialAuthState, type AuthState } from "@/features/auth/auth.slice";
import {
  initialCustomersState,
  type CustomersState,
} from "@/features/customers/customers.slice";
import {
  initialDriversState,
  type DriversState,
} from "@/features/drivers/drivers.slice";
import {
  initialWalletsState,
  type WalletsState,
} from "@/features/wallets/wallets.slice";

export type RootState = {
  auth: AuthState;
  customers: CustomersState;
  drivers: DriversState;
  wallets: WalletsState;
};

const state: RootState = {
  auth: initialAuthState,
  customers: initialCustomersState,
  drivers: initialDriversState,
  wallets: initialWalletsState,
};

export const store = {
  getState: () => state,
  dispatch: <T,>(action: T) => action,
  subscribe: (listener: () => void) => {
    listener();
    return () => undefined;
  },
};

export type AppDispatch = typeof store.dispatch;
