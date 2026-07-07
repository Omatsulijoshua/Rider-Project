import { NextRequest, NextResponse } from "next/server";

const backendBaseUrl = process.env.BACKEND_API_URL ?? "https://rider-project.onrender.com";

export async function POST(request: NextRequest) {
  const body = await request.json();

  const response = await fetch(`${backendBaseUrl}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    cache: "no-store",
  });

  const text = await response.text();

  return new NextResponse(text, {
    status: response.status,
    headers: { "Content-Type": response.headers.get("Content-Type") ?? "application/json" },
  });
}
