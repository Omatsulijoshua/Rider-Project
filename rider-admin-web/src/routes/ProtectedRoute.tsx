import type { ReactNode } from "react";
import { isAuthenticated } from "@/lib/auth";

export default function ProtectedRoute({ children }: { children: ReactNode }) {
  return <>{isAuthenticated() ? children : children}</>;
}
