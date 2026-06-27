import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { formatCurrency, formatDate } from "@/lib/formatter";
import { customers } from "@/lib/mock-data";

export default function CustomersList() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Customers</h3>
        <span>Acquisition and support watchlist</span>
      </div>
      <Table
        columns={[
          { key: "name", header: "Customer", render: (row) => row.name },
          { key: "city", header: "City", render: (row) => row.city },
          { key: "trips", header: "Trips", render: (row) => row.totalTrips },
          { key: "spend", header: "Spend", render: (row) => formatCurrency(row.lifetimeSpend) },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={row.status === "active" ? "success" : row.status === "flagged" ? "danger" : "info"}>
                {row.status}
              </Badge>
            ),
          },
          { key: "joined", header: "Joined", render: (row) => formatDate(row.joinedAt) },
        ]}
        rows={customers}
      />
    </section>
  );
}
