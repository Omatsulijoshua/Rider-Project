import Table from "@/components/ui/Table";
import { formatCurrency, formatNumber } from "@/lib/formatter";
import { driverEarningsReport } from "@/lib/mock-data";

export default function DriverEarnings() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Driver earnings tiers</h3>
        <span>Supply-side health</span>
      </div>
      <Table
        columns={[
          { key: "label", header: "Segment", render: (row) => row.label },
          { key: "earnings", header: "Avg payout", render: (row) => formatCurrency(row.primary) },
          { key: "count", header: "Drivers", render: (row) => formatNumber(row.secondary) },
        ]}
        rows={driverEarningsReport}
      />
    </section>
  );
}
