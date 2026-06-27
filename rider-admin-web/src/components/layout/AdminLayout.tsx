"use client";

import React from "react";
import type { RouteKey } from "@/config/routes";

interface AdminLayoutProps {
  activeRoute: RouteKey;
  title: string;
  subtitle: string;
  onNavigate: (route: RouteKey) => void;
  children: React.ReactNode;
}

const navItems: { key: RouteKey; label: string; icon: string }[] = [
  { key: "overview", label: "Overview", icon: "🎛️" },
  { key: "customers", label: "Customers", icon: "👥" },
  { key: "drivers", label: "Drivers", icon: "🚗" },
  { key: "rides", label: "Rides", icon: "📍" },
  { key: "wallets", label: "Wallets", icon: "💳" },
  { key: "payouts", label: "Payouts", icon: "💸" },
  { key: "fraud", label: "Fraud Alerts", icon: "🚨" },
  { key: "reports", label: "Reports", icon: "📊" },
  { key: "settings", label: "Settings", icon: "⚙️" },
];

export default function AdminLayout({
  activeRoute,
  title,
  subtitle,
  onNavigate,
  children,
}: AdminLayoutProps) {
  return (
    <div className="admin-shell">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="brand">
          <div className="brand__mark">R</div>
          <div>
            <p className="brand__eyebrow">RiderHQ</p>
            <h1>Admin</h1>
          </div>
        </div>

        <nav className="sidebar__nav">
          {navItems.map((item) => (
            <button
              key={item.key}
              onClick={() => onNavigate(item.key)}
              className={`sidebar__link ${activeRoute === item.key ? "is-active" : ""}`}
            >
              <span style={{ marginRight: "0.75rem" }}>{item.icon}</span>
              {item.label}
            </button>
          ))}
        </nav>

        <div className="sidebar__support">
          <p style={{ margin: 0, fontSize: "0.85rem", opacity: 0.8 }}>
            <strong>System Status</strong>
          </p>
          <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginTop: "0.5rem" }}>
            <span style={{ height: 8, width: 8, borderRadius: "50%", background: "#15803d" }} />
            <span style={{ fontSize: "0.8rem", opacity: 0.7 }}>All services operational</span>
          </div>
        </div>
      </aside>

      {/* Main content area */}
      <main className="admin-main">
        {/* Topbar */}
        <header className="topbar">
          <div>
            <h2>{title}</h2>
            <p className="muted-copy" style={{ margin: "0.2rem 0 0" }}>{subtitle}</p>
          </div>
          <div className="topbar__actions">
            <span className="pulse-chip">🟢 Live Data</span>
          </div>
        </header>

        {/* Content body */}
        <div className="admin-content">{children}</div>
      </main>
    </div>
  );
}
