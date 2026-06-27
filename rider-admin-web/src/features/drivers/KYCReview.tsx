import Badge from "@/components/ui/Badge";
import { drivers } from "@/lib/mock-data";

export default function KYCReview() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>KYC review queue</h3>
        <span>{drivers.filter((driver) => driver.kycStatus === "pending").length} pending</span>
      </div>
      <div className="stack-list">
        {drivers.map((driver) => (
          <div className="list-row" key={driver.id}>
            <div>
              <strong>{driver.name}</strong>
              <p className="muted-copy">{driver.city}</p>
            </div>
            <Badge
              tone={
                driver.kycStatus === "approved"
                  ? "success"
                  : driver.kycStatus === "pending"
                    ? "warning"
                    : "danger"
              }
            >
              {driver.kycStatus}
            </Badge>
          </div>
        ))}
      </div>
    </section>
  );
}
