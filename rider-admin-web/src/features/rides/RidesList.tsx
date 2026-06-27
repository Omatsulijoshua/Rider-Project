import { useEffect, useState } from "react";
import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { formatCurrency, formatDateTime } from "@/lib/formatter";
import { getRides } from "./rides.api";

export default function RidesList() {
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getRides()
      .then((res) => {
        setData(Array.isArray(res) ? res : []);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch rides:", err);
        setLoading(false);
      });
  }, []);

  if (loading) return <div className="p-4 text-center">Loading orders...</div>;

  return (
    <section className="card">
      <div className="section-heading">
        <h3>Package Monitor</h3>
        <span>Track B2B deliveries and status updates</span>
      </div>
      <Table
        columns={[
          { key: "id", header: "ID", render: (row) => row.id.split('-')[0] },
          { key: "item", header: "Item Type", render: (row) => row.itemType || "N/A" },
          { key: "customer", header: "Sender", render: (row) => row.customer?.name || "Unknown" },
          { key: "company", header: "From/To Company", render: (row) => (
            <div>
              <div className="text-xs font-semibold">{row.pickupCompanyName || "N/A"}</div>
              <div className="text-xs text-muted">→ {row.dropoffCompanyName || "N/A"}</div>
            </div>
          )},
          { key: "recipient", header: "Recipient", render: (row) => row.recipientName || "N/A" },
          { key: "fare", header: "Fare", render: (row) => formatCurrency(row.price) },
          { key: "date", header: "Date", render: (row) => formatDateTime(row.createdAt) },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={
                row.status === "COMPLETED" ? "success" : 
                row.status === "CANCELLED" ? "danger" : 
                row.status === "REQUESTED" ? "warning" : "info"
              }>
                {row.status}
              </Badge>
            ),
          },
        ]}
        rows={data}
      />
    </section>
  );
}
