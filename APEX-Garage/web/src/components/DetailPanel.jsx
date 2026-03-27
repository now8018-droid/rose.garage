import FuelBar from './FuelBar';
import StatsSection from './StatsSection';
import ActionButtons from './ActionButtons';

export default function DetailPanel({ car, onAction }) {
  if (!car) return <aside className="detail-panel" />;

  return (
    <aside className="detail-panel">
      <header className="detail-header">
        <small>Car Name</small>
        <h3>{car.name}</h3>
      </header>

      <img src={car.image} alt={car.name} className="detail-image" />

      <div className="plate-pill">JJ1281G1</div>

      <FuelBar value={car.fuel} />
      <StatsSection car={car} />
      <ActionButtons onAction={onAction} />
    </aside>
  );
}
