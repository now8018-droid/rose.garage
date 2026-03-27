import CarCard from './CarCard';

export default function CarList({ cars, selectedCarId, onSelect }) {
  return (
    <section className="car-list" aria-label="Vehicles">
      {cars.map((car) => (
        <CarCard key={car.id} car={car} active={selectedCarId === car.id} onSelect={onSelect} />
      ))}
    </section>
  );
}
