import { rides } from "@/lib/mock-data";

export default function RideDetails() {
  const ride = rides[1];

  return (
    <section className="card spotlight-card">
      <div className="section-heading">
        <h3>Dispute snapshot</h3>
        <span>{ride.id}</span>
      </div>
      <div className="detail-grid">
        <div>
          <strong>{ride.pickup}</strong>
          <p className="muted-copy">Pickup</p>
        </div>
        <div>
          <strong>{ride.destination}</strong>
          <p className="muted-copy">Destination</p>
        </div>
        <div>
          <strong>{ride.distanceKm} km</strong>
          <p className="muted-copy">Distance</p>
        </div>
      </div>
    </section>
  );
}
