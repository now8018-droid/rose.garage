const CarCard = ({ car, selected, onSelect, onToggleFav, onSpawn, onTrunk }) => {
  return (
    <article className={`car-card ${selected ? 'selected' : ''} ${car.inPound ? 'in-pound' : ''}`} onClick={() => onSelect(car.id)}>
      <div className="card-top">
        <div>
          <label>Car Name</label>
          <h3>{car.name}</h3>
        </div>
        <button
          className={`mini-icon ${car.favorite ? 'fav-active' : ''}`}
          onClick={(e) => {
            e.stopPropagation();
            onToggleFav(car.id);
          }}
        >
          <iconify-icon icon="solar:star-bold"></iconify-icon>
        </button>
      </div>

      <img src={car.image} onError={(e) => (e.target.src = './img/model_car1.png')} alt={car.name} className="card-car-image" />

      <div className="card-bottom">
        <button
          className="select-btn"
          onClick={(e) => {
            e.stopPropagation();
            onSpawn(car);
          }}
        >
          <iconify-icon icon="solar:steering-wheel-bold"></iconify-icon>
          Select
        </button>
        <button
          className="mini-icon"
          onClick={(e) => {
            e.stopPropagation();
            onTrunk(car);
          }}
        >
          <iconify-icon icon="solar:bag-4-bold"></iconify-icon>
        </button>
      </div>
      <div className="card-noise"></div>
    </article>
  );
};

window.CarCard = CarCard;
