import type { RouteKey } from "@/config/routes";
import { routes } from "@/config/routes";

export const appRouter = Object.entries(routes).map(([key, href]) => ({
  key: key as RouteKey,
  href,
}));

export default appRouter;
