const ActionButtons = ({ car, onTrunk, onSpawn }) => (
  <div className="actions-wrap">
    <div className="actions-row">
      <button className="action-btn" onClick={() => onTrunk(car)}>
        <iconify-icon icon="solar:bag-4-bold"></iconify-icon>
        Tanken
      </button>
      <button className="action-btn">
        <iconify-icon icon="solar:archive-bold"></iconify-icon>
        Kofferraum
      </button>
    </div>

    <button className="drive-btn" onClick={() => onSpawn(car)}>
      <iconify-icon icon="solar:steering-wheel-bold"></iconify-icon>
      Drive Car
    </button>
  </div>
);

window.ActionButtons = ActionButtons;
