"use client";

import {
  CategoryScale,
  Chart as ChartJS,
  Filler,
  Legend,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip,
} from "chart.js";
import { Line } from "react-chartjs-2";
import type { TrendPoint } from "@/lib/mock-data";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler);

export default function EarningsChart({ data }: { data: TrendPoint[] }) {
  return (
    <div className="chart-card card">
      <div className="section-heading">
        <h3>Earnings velocity</h3>
        <span>This week</span>
      </div>
      <Line
        data={{
          labels: data.map((item) => item.label),
          datasets: [
            {
              label: "Revenue",
              data: data.map((item) => item.value),
              fill: true,
              borderColor: "#f97316",
              backgroundColor: "rgba(249, 115, 22, 0.12)",
              tension: 0.35,
            },
          ],
        }}
        options={{ responsive: true, plugins: { legend: { display: false } } }}
      />
    </div>
  );
}
