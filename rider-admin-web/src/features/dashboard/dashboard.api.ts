import api from "@/lib/axios";
import type { AdminConsoleData } from "@/types/admin-console";

export async function fetchDashboardSummary() {
  const response = await api.get<AdminConsoleData>("/admin/console");
  return response;
}
