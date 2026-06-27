import api from "@/lib/axios";

export async function loginAdmin(credentials: { email: string; password: string }) {
  return api.post<{ accessToken: string; refreshToken: string }, {
    email: string;
    password: string;
    deviceInfo: { deviceId: string; deviceName: string; ip: string };
  }>("/auth/login", {
    email: credentials.email,
    password: credentials.password,
    deviceInfo: {
      deviceId: typeof window === "undefined" ? "server" : window.navigator.userAgent,
      deviceName: typeof window === "undefined" ? "server" : window.navigator.platform,
      ip: "127.0.0.1",
    },
  });
}
