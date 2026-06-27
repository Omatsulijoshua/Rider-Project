import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { formatCurrency, formatDateTime } from "@/lib/formatter";
import { payoutRequests } from "@/lib/mock-data";

export default function PayoutRequests() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Payout requests</h3>
        <span>Approval queue</span>
      </div>
      <Table
        columns={[
          { key: "id", header: "Ref", render: (row) => row.id },
          { key: "driver", header: "Driver", render: (row) => row.driver },
          { key: "bank", header: "Bank", render: (row) => row.bank },
          { key: "amount", header: "Amount", render: (row) => formatCurrency(row.amount) },
          { key: "time", header: "Requested", render: (row) => formatDateTime(row.requestedAt) },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={row.status === "approved" ? "success" : row.status === "queued" ? "warning" : "danger"}>
                {row.status}
              </Badge>
            ),
          },
        ]}
        rows={payoutRequests}
      />
    </section>
  );
}
