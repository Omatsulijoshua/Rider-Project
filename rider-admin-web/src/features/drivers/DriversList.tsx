import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { drivers } from "@/lib/mock-data";
import { formatCurrency } from "@/lib/formatter";

export default function DriversList() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Drivers</h3>
        <span>Availability, rating, and earnings</span>
      </div>
      <Table
        columns={[
          { key: "name", header: "Driver", render: (row) => row.name },
          { key: "vehicle", header: "Vehicle", render: (row) => row.vehicle },
          { key: "rating", header: "Rating", render: (row) => `${row.rating} / 5` },
          { key: "rate", header: "Acceptance", render: (row) => `${row.acceptanceRate}%` },
          { key: "earnings", header: "Today", render: (row) => formatCurrency(row.earningsToday) },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={row.status === "online" ? "success" : row.status === "offline" ? "neutral" : "danger"}>
                {row.status}
              </Badge>
            ),
          },
        ]}
        rows={drivers}
      />
    </section>
  );
}
