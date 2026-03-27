import { useCallback, useEffect, useMemo, useState } from 'react';
import TopBar from './components/TopBar';
import CarList from './components/CarList';
import DetailPanel from './components/DetailPanel';
const DEFAULT_CARS = Array.from({ length: 12 }, (_, index) => ({
  id: `car-${index + 1}`,
  name: 'PORSCHE GT4 RS',
  image: '/ui/img/model_car2.png',
  favorite: index === 0,
  plate: `JJ12${600 + index}`,
  fuel: 100,
  weight: '50kg',
  topSpeed: '450km',
  type: 'Supersport'
}));

const nuiPost = async (endpoint, payload) => {
  const resourceName = typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'APEX-Garage';

  return fetch(`https://${resourceName}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
};

function App() {
  const [visible, setVisible] = useState(true);
  const [cars, setCars] = useState(DEFAULT_CARS);
  const [search, setSearch] = useState('');
  const [selectedCarId, setSelectedCarId] = useState(DEFAULT_CARS[0]?.id);

  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data;
      if (data?.type === 'openGarage') {
        setVisible(true);
        if (Array.isArray(data.cars) && data.cars.length) {
          setCars(data.cars);
          setSelectedCarId(data.cars[0].id);
        }
      }

      if (data?.type === 'closeGarage') {
        setVisible(false);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const filteredCars = useMemo(() => {
    const lowerSearch = search.trim().toLowerCase();
    if (!lowerSearch) return cars;
    return cars.filter((car) => car.name.toLowerCase().includes(lowerSearch));
  }, [cars, search]);

  const selectedCar = filteredCars.find((car) => car.id === selectedCarId) || filteredCars[0] || cars[0];

  const onSelectCar = useCallback((carId) => {
    setSelectedCarId(carId);
    nuiPost('selectCar', { carId }).catch(() => undefined);
  }, []);

  const onAction = useCallback((action) => {
    if (!selectedCar) return;
    nuiPost(action, { carId: selectedCar.id, plate: selectedCar.plate }).catch(() => undefined);
  }, [selectedCar]);

  if (!visible) return null;

  return (
    <main className="garage-root">
      <section className="garage-panel">
        <TopBar search={search} onSearchChange={setSearch} />
        <div className="garage-content">
          <CarList cars={filteredCars} selectedCarId={selectedCar?.id} onSelect={onSelectCar} />
          <DetailPanel car={selectedCar} onAction={onAction} />
        </div>
      </section>
    </main>
  );
}

export default App;
