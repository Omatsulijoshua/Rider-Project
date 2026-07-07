import { env } from "@/config/env";
import { getToken } from "./auth";

type HttpMethod = "GET" | "POST" | "PATCH";

type RequestOptions<TBody = unknown> = {
  method?: HttpMethod;
  body?: TBody;
};

async function request<TResponse>(
  path: string,
  options: RequestOptions = {},
): Promise<TResponse> {
  const { method = "GET", body } = options;
  const token = getToken();
  const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? "https://rider-project.onrender.com/api";
  const url = path.startsWith("http") ? path : `${baseUrl}${path}`;
  const response = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    cache: "no-store",
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(message || `Request failed with status ${response.status}`);
  }

  return response.json() as Promise<TResponse>;
}

const api = {
  get: <TResponse>(path: string) => request<TResponse>(path),
  post: <TResponse, TBody = unknown>(path: string, body?: TBody) =>
    request<TResponse>(path, { method: "POST", body }),
  patch: <TResponse, TBody = unknown>(path: string, body?: TBody) =>
    request<TResponse>(path, { method: "PATCH", body }),
};

export default api;
