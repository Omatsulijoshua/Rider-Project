import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { fraudAlerts } from "@/lib/mock-data";

export default function FraudAlerts() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Fraud alerts</h3>
        <span>Incidents needing attention</span>
      </div>
      <Table
        columns={[
          { key: "subject", header: "Incident", render: (row) => row.subject },
          { key: "rule", header: "Rule", render: (row) => row.rule },
          { key: "city", header: "City", render: (row) => row.city },
          { key: "score", header: "Score", render: (row) => row.score },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={row.status === "resolved" ? "success" : row.status === "reviewing" ? "warning" : "danger"}>
                {row.status}
              </Badge>
            ),
          },
        ]}
        rows={fraudAlerts}
      />
    </section>
  );
}
