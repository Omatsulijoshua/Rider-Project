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
import type { AdminConsoleLiveDriver } from "@/types/admin-console";

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
  const [driverVehicleFilter, setDriverVehicleFilter] = useState("all");
  const [driverStatusFilter, setDriverStatusFilter] = useState("all");
  const [driverMinRating, setDriverMinRating] = useState("0");
  const [driverActiveDelivery, setDriverActiveDelivery] = useState("all");
  const [driverLocationLat, setDriverLocationLat] = useState("");
  const [driverLocationLng, setDriverLocationLng] = useState("");
  const [driverLocationRadius, setDriverLocationRadius] = useState("10");
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

  useEffect(() => {
    if (!isMounted || !getToken()) return;
    const timer = window.setInterval(() => {
      void loadDashboard();
    }, 10000);

    return () => window.clearInterval(timer);
  }, [isMounted]);

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

    const hasLocationFilter = driverLocationLat.trim() !== "" && driverLocationLng.trim() !== "";
    const filterLat = Number(driverLocationLat);
    const filterLng = Number(driverLocationLng);
    const filterRadius = Number(driverLocationRadius || 10);
    const filteredLiveDrivers = consoleData.liveDrivers.filter((driver) => {
      const vehicleMatches =
        driverVehicleFilter === "all" || driver.vehicleType === driverVehicleFilter;
      const statusMatches =
        driverStatusFilter === "all" || driver.status === driverStatusFilter;
      const ratingMatches = driver.rating >= Number(driverMinRating);
      const activeDeliveryMatches =
        driverActiveDelivery === "all" ||
        (driverActiveDelivery === "active" && driver.activeDeliveryCount > 0) ||
        (driverActiveDelivery === "idle" && driver.activeDeliveryCount === 0);
      const locationMatches =
        !hasLocationFilter ||
        (driver.lat !== null &&
          driver.lng !== null &&
          calculateDistanceKm(filterLat, filterLng, driver.lat, driver.lng) <= filterRadius);

      return vehicleMatches && statusMatches && ratingMatches && activeDeliveryMatches && locationMatches;
    });

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
          <div className="stack-list">
            <section className="card">
              <div className="section-heading">
                <h3>Live driver map</h3>
                <span>{filteredLiveDrivers.length} visible drivers</span>
              </div>
              <div className="filter-row">
                <select value={driverVehicleFilter} onChange={(event) => setDriverVehicleFilter(event.target.value)}>
                  <option value="all">All vehicles</option>
                  <option value="bike">Bike</option>
                  <option value="car">Car</option>
                  <option value="bus">Bus</option>
                  <option value="mini truck">Mini truck</option>
                  <option value="big truck">Big truck</option>
                </select>
                <select value={driverStatusFilter} onChange={(event) => setDriverStatusFilter(event.target.value)}>
                  <option value="all">All status</option>
                  <option value="AVAILABLE">Available</option>
                  <option value="BUSY">Busy</option>
                  <option value="ON_DELIVERY">On delivery</option>
                  <option value="OFFLINE">Offline</option>
                </select>
                <select value={driverMinRating} onChange={(event) => setDriverMinRating(event.target.value)}>
                  <option value="0">Any rating</option>
                  <option value="3">3+ rating</option>
                  <option value="4">4+ rating</option>
                  <option value="4.5">4.5+ rating</option>
                </select>
                <select value={driverActiveDelivery} onChange={(event) => setDriverActiveDelivery(event.target.value)}>
                  <option value="all">All delivery state</option>
                  <option value="active">Active delivery</option>
                  <option value="idle">No active delivery</option>
                </select>
                <input
                  value={driverLocationLat}
                  onChange={(event) => setDriverLocationLat(event.target.value)}
                  placeholder="Latitude"
                />
                <input
                  value={driverLocationLng}
                  onChange={(event) => setDriverLocationLng(event.target.value)}
                  placeholder="Longitude"
                />
                <input
                  value={driverLocationRadius}
                  onChange={(event) => setDriverLocationRadius(event.target.value)}
                  placeholder="Radius km"
                />
              </div>
              <LiveDriverMap drivers={filteredLiveDrivers} />
            </section>
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
                  {
                    key: "driverStatus",
                    header: "Driver status",
                    render: (row) => <Badge tone={toneForStatus(row.driverStatus)}>{row.driverStatus}</Badge>,
                  },
                  { key: "vehicle", header: "Vehicle", render: (row) => row.vehicleType },
                  { key: "rating", header: "Rating", render: (row) => row.rating.toFixed(1) },
                  { key: "wallet", header: "Wallet", render: (row) => formatCurrency(row.walletBalance) },
                  { key: "orders", header: "Orders", render: (row) => formatNumber(row.totalOrders) },
                  {
                    key: "fraud",
                    header: "Fraud score",
                    render: (row) => <Badge tone={row.fraudScore > 20 ? "danger" : "neutral"}>{row.fraudScore}</Badge>,
                  },
                ]}
                rows={consoleData.drivers}
              />
            </section>
          </div>
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
  }, [
    activeRoute,
    consoleData,
    driverActiveDelivery,
    driverLocationLat,
    driverLocationLng,
    driverLocationRadius,
    driverMinRating,
    driverStatusFilter,
    driverVehicleFilter,
    error,
    loading,
    metricCards,
  ]);

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
                  <p className="muted-copy">/api/admin {"->"} backend on Render</p>
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

function LiveDriverMap({ drivers }: { drivers: AdminConsoleLiveDriver[] }) {
  const visibleDrivers = drivers.slice(0, 18);
  const positionedDrivers = positionDriversOnMap(visibleDrivers);

  return (
    <div className="live-map">
      <div className="live-map__canvas">
        {positionedDrivers.map((item) => (
          <button
            className={`driver-pin ${item.driver.isOnline ? "is-online" : "is-offline"} ${
              item.driver.offlineDuringDelivery ? "has-alert" : ""
            }`}
            key={item.driver.id}
            style={{
              left: `${item.left}%`,
              top: `${item.top}%`,
            }}
            title={`${item.driver.name} - ${item.driver.status}`}
          >
            {item.driver.vehicleType.slice(0, 1).toUpperCase()}
          </button>
        ))}
      </div>
      <div className="live-map__list">
        {visibleDrivers.map((driver) => (
          <div className="list-row" key={driver.id}>
            <div>
              <strong>{driver.name}</strong>
              <p className="muted-copy">
                {driver.vehicleType} / {driver.rating.toFixed(1)} rating / {driver.completedJobs} jobs
              </p>
              <p className="muted-copy">
                Last active {driver.lastActiveAt ? formatDateTime(driver.lastActiveAt) : "not recorded"}
              </p>
            </div>
            <div className="driver-badges">
              <Badge tone={toneForStatus(driver.status)}>{driver.status}</Badge>
              {driver.activeDeliveryCount > 0 ? <Badge tone="info">{driver.activeDeliveryCount} active</Badge> : null}
              {driver.offlineDuringDelivery ? <Badge tone="danger">flagged</Badge> : null}
            </div>
          </div>
        ))}
        {visibleDrivers.length === 0 ? <p className="muted-copy">No drivers match the selected filters.</p> : null}
      </div>
    </div>
  );
}

function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number) {
  const earthRadiusKm = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function positionDriversOnMap(drivers: AdminConsoleLiveDriver[]) {
  const validDrivers = drivers.filter((driver) => driver.lat !== null && driver.lng !== null);
  const lats = validDrivers.map((driver) => driver.lat as number);
  const lngs = validDrivers.map((driver) => driver.lng as number);
  const minLat = Math.min(...lats);
  const maxLat = Math.max(...lats);
  const minLng = Math.min(...lngs);
  const maxLng = Math.max(...lngs);
  const latRange = Math.max(0.0001, maxLat - minLat);
  const lngRange = Math.max(0.0001, maxLng - minLng);

  return drivers.map((driver, index) => {
    if (driver.lat === null || driver.lng === null || validDrivers.length === 0) {
      return {
        driver,
        left: 12 + ((index * 23) % 76),
        top: 18 + ((index * 17) % 62),
      };
    }

    return {
      driver,
      left: 8 + ((driver.lng - minLng) / lngRange) * 84,
      top: 8 + ((maxLat - driver.lat) / latRange) * 84,
    };
  });
}
