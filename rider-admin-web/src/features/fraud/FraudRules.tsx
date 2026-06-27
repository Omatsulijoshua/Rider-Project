import Badge from "@/components/ui/Badge";
import { fraudRules } from "@/lib/mock-data";
import { formatPercentage } from "@/lib/formatter";

export default function FraudRules() {
  return (
    <section className="card">
      <div className="section-heading">
        <h3>Fraud rules</h3>
        <span>Automated safeguards</span>
      </div>
      <div className="stack-list">
        {fraudRules.map((rule) => (
          <div className="list-row" key={rule.id}>
            <div>
              <strong>{rule.name}</strong>
              <p className="muted-copy">{rule.action}</p>
            </div>
            <div className="list-row__meta">
              <Badge tone={rule.sensitivity === "high" ? "danger" : rule.sensitivity === "medium" ? "warning" : "info"}>
                {rule.sensitivity}
              </Badge>
              <span>{formatPercentage(rule.hitRate)}</span>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
