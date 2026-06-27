import { drivers } from "@/lib/mock-data";
import type { Driver } from "@/types/driver";

export type DriversState = {
  items: Driver[];
};

export const initialDriversState: DriversState = {
  items: drivers,
};
