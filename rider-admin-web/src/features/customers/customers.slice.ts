import { customers } from "@/lib/mock-data";
import type { Customer } from "@/types/user";

export type CustomersState = {
  items: Customer[];
};

export const initialCustomersState: CustomersState = {
  items: customers,
};
