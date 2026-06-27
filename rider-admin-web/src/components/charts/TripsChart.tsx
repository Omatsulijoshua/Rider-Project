"use client";

import {
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  Legend,
  LinearScale,
  Tooltip,
} from "chart.js";
import { Bar } from "react-chartjs-2";
import type { TrendPoint } from "@/lib/mock-data";

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip, Legend);

export default function TripsChart({ data }: { data: TrendPoint[] }) {
  return (
    <div className="chart-card card">
      <div className="section-heading">
        <h3>Trip distribution</h3>
        <span>Peak demand</span>
      </div>
      <Bar
        data={{
          labels: data.map((item) => item.label),
          datasets: [
            {
              label: "Trips",
              data: data.map((item) => item.value),
              backgroundColor: ["#0f766e", "#14b8a6", "#22c55e", "#84cc16", "#f59e0b", "#f97316"],
              borderRadius: 10,
            },
          ],
        }}
        options={{ responsive: true, plugins: { legend: { display: false } } }}
      />
    </div>
  );
}
