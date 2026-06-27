"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import EarningsChart from "@/components/charts/EarningsChart";
import TripsChart from "@/components/charts/TripsChart";
import WalletFlowChart from "@/components/charts/WalletFlowChart";
import AdminLayout from "@/components/layout/AdminLayout";
import Badge from "@/components/ui/Badge";
import Button from "@/components/ui/Button";
import Loader from "@/components/ui/Loader";
import Table from "@/components/ui/Table";
import type { RouteKey } from "@/config/routes";
import { clearToken, getToken } from "@/lib/auth";
import { formatCurrency, formatDateTime, formatNumber } from "@/lib/formatter";
import type { AdminConsoleData } from "@/types/admin-console";
import Login from "../auth/Login";
import { fetchDashboardSummary } from "./dashboard.api";

const sectionCopy: Record<RouteKey, { title: string; subtitle: string }> = {
  overview: {
    title: "Operations cockpit",
    subtitle: "Live platform balances, order flow, and admin visibility from your real backend.",
  },
  customers: {
    title: "Customer management",
    subtitle: "Users are loaded directly from your production-style user records.",
  },
  drivers: {
    title: "Driver operations",
    subtitle: "Monitor active driver accounts, wallet balances, and completed jobs.",
  },
  rides: {
    title: "Ride monitoring",
    subtitle: "Orders and ride lifecycle data are coming from the Nest backend.",
  },
  wallets: {
    title: "Wallet controls",
    subtitle: "Platform and user wallet balances are now backed by Prisma data.",
  },
  payouts: {
    title: "Payout desk",
    subtitle: "Withdrawal requests are pulled from the backend payout records.",
  },
  fraud: {
    title: "Fraud command",
    subtitle: "Fraud logs and unresolved wallet incidents are now live.",
  },
  reports: {
    title: "Performance reports",
    subtitle: "Report cards reflect real order and user status aggregates.",
  },
  settings: {
    title: "Platform settings",
    subtitle: "Admin accounts shown here come from your real users table.",
  },
};

function toneForStatus(value: string | boolean) {
  if (value === true) return "success";
  if (value === false) return "neutral";

  const normalized = String(value).toLowerCase();
  if (["active", "approved", "completed", "paid"].includes(normalized)) return "success";
  if (["pending", "requested", "accepted"].includes(normalized)) return "warning";
  if (["blocked", "suspended", "cancelled", "rejected"].includes(normalized)) return "danger";
  return "info";
}

export default function Dashboard() {
  const [activeRoute, setActiveRoute] = useState<RouteKey>("overview");
  const [consoleData, setConsoleData] = useState<AdminConsoleData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isMounted, setIsMounted] = useState(false);
  const router = useRouter();

  const loadDashboard = async () => {
    if (!getToken()) {
      setConsoleData(null);
      setLoading(false);
      setError("Sign in with an ADMIN account to load backend data.");
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await fetchDashboardSummary();
      setConsoleData(data);
    } catch (requestError) {
      setConsoleData(null);
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Unable to load admin console data.",
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setIsMounted(true);
  }, []);

  useEffect(() => {
    if (isMounted) {
      if (!getToken()) {
        router.push("/login");
      } else {
        void loadDashboard();
      }
    }
  }, [isMounted, router]);

  const metricCards = useMemo(() => {
    if (!consoleData) return [];

    return [
      {
        id: "platformBalance",
        label: "Platform balance",
        value: consoleData.summary.platformBalance,
      },
      {
        id: "driverHoldings",
        label: "Driver holdings",
        value: consoleData.summary.driverHoldings,
      },
      {
        id: "customers",
        label: "Customers",
        value: consoleData.summary.totalCustomers,
      },
      {
        id: "orders",
        label: "Total Orders",
        value: consoleData.summary.totalOrders,
      },
      {
        id: "b2bVolume",
        label: "B2B Volume",
        value: consoleData.summary.totalB2BVolume,
      },
      {
        id: "activeDriversCount",
        label: "Active Drivers",
        value: consoleData.summary.activeDriversCount,
      },
    ];
  }, [consoleData]);

  const activePanel = useMemo(() => {
    if (loading) {
      return (
        <section className="card">
          <Loader label="Loading backend dashboard" />
        </section>
      );
    }

    if (!consoleData) {
      return (
        <section className="card">
          <div className="section-heading">
            <h3>Backend connection required</h3>
            <span>Waiting for authentication</span>
          </div>
          <p className="muted-copy">{error ?? "No data loaded yet."}</p>
        </section>
      );
    }

    switch (activeRoute) {
      case "customers":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Customers</h3>
              <span>{consoleData.customers.length} records</span>
            </div>
            <Table
              columns={[
                { key: "phone", header: "Phone", render: (row) => row.phone },
                { key: "email", header: "Email", render: (row) => row.email ?? "No email" },
                { key: "orders", header: "Orders", render: (row) => formatNumber(row.totalOrders) },
                { key: "spend", header: "Spend", render: (row) => formatCurrency(row.totalSpend) },
                {
                  key: "status",
                  header: "Status",
                  render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                },
              ]}
              rows={consoleData.customers}
            />
          </section>
        );
      case "drivers":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Drivers</h3>
              <span>{consoleData.drivers.length} records</span>
            </div>
            <Table
              columns={[
                { key: "phone", header: "Phone", render: (row) => row.phone },
                { key: "email", header: "Email", render: (row) => row.email ?? "No email" },
                {
                  key: "online",
                  header: "Online",
                  render: (row) => (
                    <Badge tone={toneForStatus(row.isOnline)}>{row.isOnline ? "online" : "offline"}</Badge>
                  ),
                },
                { key: "wallet", header: "Wallet", render: (row) => formatCurrency(row.walletBalance) },
                { key: "orders", header: "Orders", render: (row) => formatNumber(row.totalOrders) },
              ]}
              rows={consoleData.drivers}
            />
          </section>
        );
      case "rides":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Orders / rides</h3>
              <span>{consoleData.rides.length} records</span>
            </div>
            <Table
              columns={[
                { key: "id", header: "Ride", render: (row) => row.id.slice(0, 8) },
                { key: "customer", header: "Customer", render: (row) => row.customerPhone },
                { key: "driver", header: "Driver", render: (row) => row.driverPhone ?? "Unassigned" },
                { key: "price", header: "Price", render: (row) => formatCurrency(row.price) },
                { key: "time", header: "Created", render: (row) => formatDateTime(row.createdAt) },
                {
                  key: "status",
                  header: "Status",
                  render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                },
              ]}
              rows={consoleData.rides}
            />
          </section>
        );
      case "wallets":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Wallets</h3>
              <span>{consoleData.wallets.length} records</span>
            </div>
            <Table
              columns={[
                { key: "type", header: "Type", render: (row) => row.type },
                { key: "owner", header: "Owner", render: (row) => row.ownerPhone ?? row.ownerEmail ?? "Platform" },
                { key: "balance", header: "Balance", render: (row) => formatCurrency(row.balance) },
                {
                  key: "frozen",
                  header: "Frozen",
                  render: (row) => <Badge tone={toneForStatus(row.frozen)}>{row.frozen ? "yes" : "no"}</Badge>,
                },
                {
                  key: "withdrawals",
                  header: "Withdrawals",
                  render: (row) => formatNumber(row.withdrawalCount),
                },
              ]}
              rows={consoleData.wallets}
            />
          </section>
        );
      case "payouts":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Payouts</h3>
              <span>{consoleData.payouts.length} records</span>
            </div>
            <Table
              columns={[
                { key: "id", header: "Request", render: (row) => row.id.slice(0, 8) },
                { key: "driver", header: "Driver", render: (row) => row.driverId.slice(0, 8) },
                { key: "amount", header: "Amount", render: (row) => formatCurrency(row.amount) },
                { key: "reason", header: "Reason", render: (row) => row.reason ?? "No reason" },
                {
                  key: "status",
                  header: "Status",
                  render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                },
              ]}
              rows={consoleData.payouts}
            />
          </section>
        );
      case "fraud":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Fraud alerts</h3>
              <span>{consoleData.fraudAlerts.length} records</span>
            </div>
            <Table
              columns={[
                { key: "id", header: "Alert", render: (row) => row.id.slice(0, 8) },
                { key: "owner", header: "Owner", render: (row) => row.ownerPhone ?? row.ownerEmail ?? "Unknown" },
                { key: "reason", header: "Reason", render: (row) => row.reason },
                { key: "time", header: "Created", render: (row) => formatDateTime(row.createdAt) },
                {
                  key: "resolved",
                  header: "Resolved",
                  render: (row) => (
                    <Badge tone={toneForStatus(row.resolved)}>{row.resolved ? "resolved" : "open"}</Badge>
                  ),
                },
              ]}
              rows={consoleData.fraudAlerts}
            />
          </section>
        );
      case "reports":
        return (
          <div className="feature-grid">
            <section className="card">
              <div className="section-heading">
                <h3>Orders by status</h3>
                <span>Backend aggregate</span>
              </div>
              <Table
                columns={[
                  { key: "label", header: "Status", render: (row) => row.label },
                  { key: "value", header: "Count", render: (row) => formatNumber(row.value) },
                ]}
                rows={consoleData.reports.ordersByStatus}
              />
            </section>
            <section className="card">
              <div className="section-heading">
                <h3>Users by status</h3>
                <span>Backend aggregate</span>
              </div>
              <Table
                columns={[
                  { key: "label", header: "Status", render: (row) => row.label },
                  { key: "value", header: "Count", render: (row) => formatNumber(row.value) },
                ]}
                rows={consoleData.reports.usersByStatus}
              />
            </section>
          </div>
        );
      case "settings":
        return (
          <section className="card">
            <div className="section-heading">
              <h3>Admin users</h3>
              <span>{consoleData.adminUsers.length} records</span>
            </div>
            <Table
              columns={[
                { key: "phone", header: "Phone", render: (row) => row.phone },
                { key: "email", header: "Email", render: (row) => row.email ?? "No email" },
                {
                  key: "status",
                  header: "Status",
                  render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                },
                { key: "created", header: "Created", render: (row) => formatDateTime(row.createdAt) },
              ]}
              rows={consoleData.adminUsers}
            />
          </section>
        );
      default:
        return (
          <>
            <section className="hero-grid">
              {metricCards.map((metric) => (
                <article className="metric-card" key={metric.id}>
                  <p>{metric.label}</p>
                  <h3>
                    {["customers", "orders", "activeDriversCount"].includes(metric.id)
                      ? formatNumber(metric.value)
                      : formatCurrency(metric.value)}
                  </h3>
                </article>
              ))}
            </section>
            <section className="analytics-grid">
              <EarningsChart data={consoleData.revenueTrend} />
              <TripsChart data={consoleData.reports.ordersByStatus} />
              <WalletFlowChart data={consoleData.reports.usersByStatus} />
            </section>
            <section className="feature-grid">
              <section className="card">
                <div className="section-heading">
                  <h3>Recent customers</h3>
                  <span>From users table</span>
                </div>
                <Table
                  columns={[
                    { key: "phone", header: "Phone", render: (row) => row.phone },
                    { key: "orders", header: "Orders", render: (row) => row.totalOrders },
                    {
                      key: "status",
                      header: "Status",
                      render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                    },
                  ]}
                  rows={consoleData.customers.slice(0, 5)}
                />
              </section>
              <section className="card">
                <div className="section-heading">
                  <h3>Recent rides</h3>
                  <span>From orders table</span>
                </div>
                <Table
                  columns={[
                    { key: "id", header: "Ride", render: (row) => row.id.slice(0, 8) },
                    { key: "price", header: "Price", render: (row) => formatCurrency(row.price) },
                    {
                      key: "status",
                      header: "Status",
                      render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                    },
                  ]}
                  rows={consoleData.rides.slice(0, 5)}
                />
              </section>
              <section className="card">
                <div className="section-heading">
                  <h3>Pending payouts</h3>
                  <span>From withdrawals table</span>
                </div>
                <Table
                  columns={[
                    { key: "id", header: "Request", render: (row) => row.id.slice(0, 8) },
                    { key: "amount", header: "Amount", render: (row) => formatCurrency(row.amount) },
                    {
                      key: "status",
                      header: "Status",
                      render: (row) => <Badge tone={toneForStatus(row.status)}>{row.status}</Badge>,
                    },
                  ]}
                  rows={consoleData.payouts.slice(0, 5)}
                />
              </section>
            </section>
          </>
        );
    }
  }, [activeRoute, consoleData, error, loading, metricCards]);

  return (
    <AdminLayout
      activeRoute={activeRoute}
      title={sectionCopy[activeRoute].title}
      subtitle={sectionCopy[activeRoute].subtitle}
      onNavigate={setActiveRoute}
    >
      <section className="overview-grid">
        <div className="overview-main">{activePanel}</div>
        <aside className="overview-side">
          <section className="card">
            <div className="section-heading">
              <h3>Backend status</h3>
              <span>{consoleData ? "connected" : "awaiting login"}</span>
            </div>
            <div className="stack-list">
              <div className="list-row">
                <div>
                  <strong>Proxy route</strong>
                  <p className="muted-copy">/api/admin {"->"} backend on localhost:3000</p>
                </div>
                <Badge tone={consoleData ? "success" : "warning"}>
                  {consoleData ? "live" : "idle"}
                </Badge>
              </div>
              <div className="list-row">
                <div>
                  <strong>Token state</strong>
                  <p className="muted-copy">
                    {isMounted && getToken() ? "Admin JWT found in local storage." : "No admin JWT stored."}
                  </p>
                </div>
                <Button
                  variant="secondary"
                  onClick={() => {
                    clearToken();
                    router.push("/login");
                  }}
                >
                  Sign out
                </Button>
              </div>
            </div>
          </section>
          <section className="card">
            <div className="section-heading">
              <h3>Live totals</h3>
              <span>Backend summary</span>
            </div>
            {consoleData ? (
              <div className="stack-list">
                <div className="list-row">
                  <span>Completed today</span>
                  <strong>{formatNumber(consoleData.summary.completedOrdersToday)}</strong>
                </div>
                <div className="list-row">
                  <span>Pending KYC</span>
                  <strong>{formatNumber(consoleData.summary.pendingKyc)}</strong>
                </div>
                <div className="list-row">
                  <span>Pending withdrawals</span>
                  <strong>{formatNumber(consoleData.summary.pendingWithdrawals)}</strong>
                </div>
              </div>
            ) : (
              <p className="muted-copy">{error ?? "Waiting for backend response."}</p>
            )}
          </section>
        </aside>
      </section>
    </AdminLayout>
  );
}
