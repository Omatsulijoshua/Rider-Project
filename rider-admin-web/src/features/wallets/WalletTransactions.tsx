import Badge from "@/components/ui/Badge";
import Table from "@/components/ui/Table";
import { formatCurrency, formatDateTime } from "@/lib/formatter";
import { walletTransactions } from "@/lib/mock-data";

export default function WalletTransactions() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Wallet transactions</h3>
        <span>Recent credits, debits, and holds</span>
      </div>
      <Table
        columns={[
          { key: "id", header: "Ref", render: (row) => row.id },
          { key: "actor", header: "Actor", render: (row) => row.actor },
          { key: "type", header: "Type", render: (row) => row.type },
          { key: "amount", header: "Amount", render: (row) => formatCurrency(row.amount) },
          { key: "time", header: "Created", render: (row) => formatDateTime(row.createdAt) },
          {
            key: "status",
            header: "Status",
            render: (row) => (
              <Badge tone={row.status === "success" ? "success" : row.status === "pending" ? "warning" : "danger"}>
                {row.status}
              </Badge>
            ),
          },
        ]}
        rows={walletTransactions}
      />
    </section>
  );
}
