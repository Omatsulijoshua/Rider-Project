import { payoutRequests } from "@/lib/mock-data";
import { formatCurrency } from "@/lib/formatter";

export default function PayoutHistory() {
  const settled = payoutRequests.filter((request) => request.status !== "queued");

  return (
    <section className="card spotlight-card">
      <div className="section-heading">
        <h3>Payout history</h3>
        <span>{settled.length} completed or failed</span>
      </div>
      <div className="detail-grid">
        {settled.map((request) => (
          <div key={request.id}>
            <strong>{formatCurrency(request.amount)}</strong>
            <p className="muted-copy">
              {request.driver} via {request.bank}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
