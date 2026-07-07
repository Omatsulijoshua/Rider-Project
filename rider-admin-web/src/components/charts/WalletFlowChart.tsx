"use client";

import {
  ArcElement,
  Chart as ChartJS,
  DoughnutController,
  Legend,
  Tooltip,
} from "chart.js";
import { Doughnut } from "react-chartjs-2";
import type { TrendPoint } from "@/lib/mock-data";

ChartJS.register(ArcElement, DoughnutController, Tooltip, Legend);

export default function WalletFlowChart({ data }: { data: TrendPoint[] }) {
  return (
    <div className="chart-card card">
      <div className="section-heading">
        <h3>Wallet movement</h3>
        <span>Monthly split</span>
      </div>
      <Doughnut
        data={{
          labels: data.map((item) => item.label),
          datasets: [
            {
              data: data.map((item) => item.value),
              backgroundColor: ["#2563eb", "#10b981", "#f59e0b", "#ef4444"],
              borderWidth: 0,
            },
          ],
        }}
      />
    </div>
  );
}
