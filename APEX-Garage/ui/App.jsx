const { useMemo, useState, useEffect } = React;

const mapVehicle = (vehicle, nowGarage, pounddeposit, favorites = []) => {
  let inPound = true;

  if (pounddeposit) {
    inPound = !vehicle.stored || !!vehicle.deposit;
  } else {
    inPound = !vehicle.stored;
  }

  if (nowGarage === 'pound') inPound = false;

  const imageName = vehicle.img || 'model_car1';

  return {
    id: vehicle.plate,
    name: (vehicle.vehiclename || 'PORSCHE GT4 RS').toUpperCase(),
    plate: vehicle.plate || 'JJ1281G1',
    image: `./img/${imageName}.png`,
    fuel: Number(vehicle.fuel || 100).toFixed(0),
    speed: Number(vehicle.maxspeed || 450).toFixed(0),
    weight: Number(vehicle.weight || 50).toFixed(0),
    className: vehicle.class || 'Supersport',
    inPound,
    favorite: favorites.includes(vehicle.plate)
  };
};

function App() {
  const [isOpen, setIsOpen] = useState(false);
  const [garageType, setGarageType] = useState('AURORA');
  const [cars, setCars] = useState([]);
  const [selectedId, setSelectedId] = useState('');
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [pounddeposit, setPounddeposit] = useState(false);
  const [renameOpen, setRenameOpen] = useState(false);
  const [renameValue, setRenameValue] = useState('');
  const [renamePlate, setRenamePlate] = useState('');

  const favorites = useMemo(() => JSON.parse(localStorage.getItem('fav-list') || '[]'), []);

  const postNui = (endpoint, payload = {}) => {
    fetch(`https://APEX-Garage/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  };

  useEffect(() => {
    const handler = (event) => {
      const data = event.data || {};
      if (data.action === 'open') setIsOpen(true);
      if (data.action === 'closeui') setIsOpen(false);
      if (data.action === 'pounddeposit') setPounddeposit(!!data.pounddeposit);
      if (data.action === 'syncData') {
        const mapped = Object.values(data.data || {}).map((vehicle) => mapVehicle(vehicle, data.type, pounddeposit, favorites));
        setGarageType(data.type || 'AURORA');
        setCars(mapped);
        setSelectedId(mapped[0]?.id || '');
      }
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [pounddeposit, favorites]);

  const selectedCar = cars.find((car) => car.id === selectedId) || cars[0];

  const visibleCars = cars.filter((car) => {
    const bySearch = car.name.toLowerCase().includes(search.toLowerCase());
    if (filter === 'all') return bySearch;
    if (filter === 'garage') return bySearch && !car.inPound;
    return bySearch && car.inPound;
  });

  const handleToggleFav = (id) => {
    const nextCars = cars.map((car) => (car.id === id ? { ...car, favorite: !car.favorite } : car));
    setCars(nextCars);
    const favIds = nextCars.filter((car) => car.favorite).map((car) => car.id);
    localStorage.setItem('fav-list', JSON.stringify(favIds));
  };

  const handleSpawn = (car) => postNui('spawnvehicle', { plate: car.id });
  const handleTrunk = (car) => postNui('trunkopen', { plate: car.id });
  const handleClose = () => {
    setIsOpen(false);
    postNui('exit', { plate: '' });
  };

  const openRename = (car) => {
    setRenamePlate(car.id);
    setRenameValue(car.name);
    setRenameOpen(true);
  };

  const submitRename = () => {
    if (renameValue.trim().length < 3) return;
    postNui('changeName', { plate: renamePlate, rename: renameValue.trim() });
    setRenameOpen(false);
  };

  if (!isOpen) return null;

  return (
    <div className="garage-root">
      <div className="garage-layout">
        <section className="left-panel">
          <window.TopBar
            title={garageType}
            search={search}
            onSearch={setSearch}
            activeFilter={filter}
            onFilter={setFilter}
            onClose={handleClose}
          />

          <window.CarList
            cars={visibleCars}
            selectedId={selectedId}
            onSelect={setSelectedId}
            onToggleFav={handleToggleFav}
            onSpawn={handleSpawn}
            onTrunk={handleTrunk}
          />
        </section>

        <window.DetailPanel
          car={selectedCar}
          onRename={openRename}
          onToggleFav={handleToggleFav}
          onTrunk={handleTrunk}
          onSpawn={handleSpawn}
        />
      </div>

      {renameOpen && (
        <div className="rename-overlay" onClick={() => setRenameOpen(false)}>
          <div className="rename-modal" onClick={(e) => e.stopPropagation()}>
            <div className="rename-title">ระบบเปลี่ยนชื่อยานพาหนะ</div>
            <input value={renameValue} onChange={(e) => setRenameValue(e.target.value)} maxLength={30} />
            <button onClick={submitRename}>บันทึก</button>
          </div>
        </div>
      )}
    </div>
  );
}

window.App = App;
ReactDOM.createRoot(document.getElementById('root')).render(<App />);
