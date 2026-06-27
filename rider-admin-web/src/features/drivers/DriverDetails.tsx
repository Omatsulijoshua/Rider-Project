import { drivers } from "@/lib/mock-data";
import { formatCurrency } from "@/lib/formatter";

export default function DriverDetails() {
  const driver = drivers[0];

  return (
    <section className="card spotlight-card">
      <div className="section-heading">
        <h3>Driver spotlight</h3>
        <span>{driver.city}</span>
      </div>
      <div className="detail-grid">
        <div>
          <strong>{driver.name}</strong>
          <p className="muted-copy">{driver.vehicle}</p>
        </div>
        <div>
          <strong>{formatCurrency(driver.walletBalance)}</strong>
          <p className="muted-copy">Wallet balance</p>
        </div>
        <div>
          <strong>{driver.acceptanceRate}%</strong>
          <p className="muted-copy">Acceptance rate</p>
        </div>
      </div>
    </section>
  );
}
