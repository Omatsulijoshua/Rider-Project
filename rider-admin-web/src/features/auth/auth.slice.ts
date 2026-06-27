export type AuthState = {
  adminName: string;
  role: string;
  isAuthenticated: boolean;
};

export const initialAuthState: AuthState = {
  adminName: "Mercy Ayo",
  role: "super_admin",
  isAuthenticated: true,
};
