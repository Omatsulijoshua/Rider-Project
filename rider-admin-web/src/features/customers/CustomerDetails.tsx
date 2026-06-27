import { customers } from "@/lib/mock-data";
import { formatCurrency } from "@/lib/formatter";

export default function CustomerDetails() {
  const featuredCustomer = customers[0];

  return (
    <section className="card spotlight-card">
      <div className="section-heading">
        <h3>Customer profile</h3>
        <span>{featuredCustomer.id}</span>
      </div>
      <div className="detail-grid">
        <div>
          <strong>{featuredCustomer.name}</strong>
          <p className="muted-copy">{featuredCustomer.email}</p>
        </div>
        <div>
          <strong>{formatCurrency(featuredCustomer.lifetimeSpend)}</strong>
          <p className="muted-copy">Lifetime spend</p>
        </div>
        <div>
          <strong>{featuredCustomer.totalTrips}</strong>
          <p className="muted-copy">Trips completed</p>
        </div>
      </div>
    </section>
  );
}
