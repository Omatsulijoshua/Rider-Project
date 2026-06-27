import api from "@/lib/axios";

export async function getRides() {
  return api.get("/orders/all");
}
