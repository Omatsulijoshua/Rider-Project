export type RideStatus = "completed" | "in_progress" | "cancelled" | "disputed";

export type Ride = {
  id: string;
  rider: string;
  driver: string;
  pickup: string;
  destination: string;
  fare: number;
  distanceKm: number;
  status: RideStatus;
  startedAt: string;
};
