import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "RiderHQ Admin",
  description: "Operations command center for rider, wallet, fraud, and payout teams.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>{children}</body>
    </html>
  );
}
