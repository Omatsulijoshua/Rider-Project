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
  { key: "overview", label: "Overview", icon: "OV" },
  { key: "customers", label: "Customers", icon: "CU" },
  { key: "drivers", label: "Drivers", icon: "DR" },
  { key: "rides", label: "Rides", icon: "RD" },
  { key: "wallets", label: "Wallets", icon: "WA" },
  { key: "payouts", label: "Payouts", icon: "PO" },
  { key: "fraud", label: "Fraud Alerts", icon: "FR" },
  { key: "reports", label: "Reports", icon: "RP" },
  { key: "settings", label: "Settings", icon: "ST" },
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
      <aside className="sidebar">
        <div className="brand">
          <div className="brand__mark">RL</div>
          <div>
            <p className="brand__eyebrow">Rider Logistics</p>
            <h1>Command</h1>
          </div>
        </div>

        <nav className="sidebar__nav">
          {navItems.map((item) => (
            <button
              key={item.key}
              onClick={() => onNavigate(item.key)}
              className={`sidebar__link ${activeRoute === item.key ? "is-active" : ""}`}
            >
              <span className="sidebar__icon">{item.icon}</span>
              {item.label}
            </button>
          ))}
        </nav>

        <div className="sidebar__support">
          <p className="sidebar__support-title">
            <strong>System status</strong>
          </p>
          <div className="sidebar__status">
            <span />
            <small>All services operational</small>
          </div>
        </div>
      </aside>

      <main className="admin-main">
        <header className="topbar">
          <div>
            <h2>{title}</h2>
            <p className="muted-copy" style={{ margin: "0.2rem 0 0" }}>{subtitle}</p>
          </div>
          <div className="topbar__actions">
            <span className="pulse-chip">Live Data</span>
          </div>
        </header>

        <div className="admin-content">{children}</div>
      </main>
    </div>
  );
}
