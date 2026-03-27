const DetailPanel = ({ car, onRename, onToggleFav, onTrunk, onSpawn }) => {
  if (!car) return <aside className="detail-panel" />;

  return (
    <aside className="detail-panel">
      <div className="detail-header">
        <div>
          <p>Car Name</p>
          <h2>{car.name}</h2>
        </div>
        <div className="detail-icons">
          <button className="mini-icon" onClick={() => onRename(car)}><iconify-icon icon="solar:pen-bold"></iconify-icon></button>
          <button className={`mini-icon ${car.favorite ? 'fav-active' : ''}`} onClick={() => onToggleFav(car.id)}><iconify-icon icon="solar:star-bold"></iconify-icon></button>
        </div>
      </div>

      <div className="detail-preview">
        <img src={car.image} onError={(e) => (e.target.src = './img/model_car1.png')} alt={car.name} />
      </div>

      <div className="plate-box">{car.plate}</div>

      <window.StatsSection car={car} />
      <window.ActionButtons car={car} onTrunk={onTrunk} onSpawn={onSpawn} />
      <div className="panel-noise"></div>
    </aside>
  );
};

window.DetailPanel = DetailPanel;
