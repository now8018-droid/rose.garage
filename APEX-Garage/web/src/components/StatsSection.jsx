const StatItem = ({ icon, label, value }) => (
  <div className="stat-row">
    <span className="stat-icon">{icon}</span>
    <div className="stat-copy">
      <small>{label}</small>
      <strong>{value}</strong>
    </div>
  </div>
);

export default function StatsSection({ car }) {
  return (
    <section className="stats-section">
      <StatItem icon="📦" label="Kofferraum" value={car.weight} />
      <StatItem icon="⇧" label="Top Speed" value={car.topSpeed} />
      <StatItem icon="⬡" label="Car Type" value={car.type} />
    </section>
  );
}
