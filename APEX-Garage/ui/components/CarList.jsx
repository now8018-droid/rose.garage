const CarList = ({ cars, selectedId, onSelect, onToggleFav, onSpawn, onTrunk }) => {
  return (
    <section className="car-list-grid">
      {cars.map((car) => (
        <window.CarCard
          key={car.id}
          car={car}
          selected={selectedId === car.id}
          onSelect={onSelect}
          onToggleFav={onToggleFav}
          onSpawn={onSpawn}
          onTrunk={onTrunk}
        />
      ))}
    </section>
  );
};

window.CarList = CarList;
