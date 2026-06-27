import Table from "@/components/ui/Table";
import { formatCurrency, formatNumber } from "@/lib/formatter";
import { revenueReport } from "@/lib/mock-data";

export default function RevenueReport() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Revenue by city</h3>
        <span>Marketplace performance</span>
      </div>
      <Table
        columns={[
          { key: "label", header: "City", render: (row) => row.label },
          { key: "revenue", header: "Revenue", render: (row) => formatCurrency(row.primary) },
          { key: "rides", header: "Trips", render: (row) => formatNumber(row.secondary) },
        ]}
        rows={revenueReport}
      />
    </section>
  );
}
