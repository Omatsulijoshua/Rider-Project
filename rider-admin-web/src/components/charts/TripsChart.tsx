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
              backgroundColor: ["#2563eb", "#0891b2", "#10b981", "#f59e0b", "#ef4444", "#7c3aed"],
              borderRadius: 10,
            },
          ],
        }}
        options={{ responsive: true, plugins: { legend: { display: false } } }}
      />
    </div>
  );
}
