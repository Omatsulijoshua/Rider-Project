import { formatCurrency } from "@/lib/formatter";
import { freezeCases } from "@/lib/mock-data";

export default function WalletFreeze() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Freeze cases</h3>
        <span>Held balances under review</span>
      </div>
      <div className="stack-list">
        {freezeCases.map((freezeCase) => (
          <div className="list-row" key={freezeCase.id}>
            <div>
              <strong>{freezeCase.owner}</strong>
              <p className="muted-copy">{freezeCase.reason}</p>
            </div>
            <div className="list-row__meta">
              <strong>{formatCurrency(freezeCase.amount)}</strong>
              <span className="muted-copy">{freezeCase.state}</span>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
