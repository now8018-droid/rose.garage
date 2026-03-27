export default function CarCard({ car, active, onSelect }) {
  return (
    <article className={`car-card ${active ? 'active' : ''}`}>
      <div className="car-card-header">
        <div>
          <small>Car Name</small>
          <h4>{car.name}</h4>
        </div>
        <button type="button" className="star-btn" aria-label="Favorite">☆</button>
      </div>

      <img src={car.image} alt={car.name} className="car-thumb" />

      <button type="button" className="select-btn" onClick={() => onSelect(car.id)}>
        Select
      </button>
    </article>
  );
}
