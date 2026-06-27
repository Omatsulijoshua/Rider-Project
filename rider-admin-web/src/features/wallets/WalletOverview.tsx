import Badge from "@/components/ui/Badge";
import { formatCurrency, formatDateTime } from "@/lib/formatter";
import { wallets } from "@/lib/mock-data";

export default function WalletOverview() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Wallet overview</h3>
        <span>Liquidity and settlement readiness</span>
      </div>
      <div className="stack-list">
        {wallets.map((wallet) => (
          <div className="list-row" key={wallet.owner}>
            <div>
              <strong>{wallet.owner}</strong>
              <p className="muted-copy">Last settlement {formatDateTime(wallet.lastSettlement)}</p>
            </div>
            <div className="list-row__meta">
              <strong>{formatCurrency(wallet.balance)}</strong>
              <Badge tone={wallet.status === "healthy" ? "success" : wallet.status === "review" ? "warning" : "danger"}>
                {wallet.status}
              </Badge>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
