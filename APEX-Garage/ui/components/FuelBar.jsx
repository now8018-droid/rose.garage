const FuelBar = ({ value }) => {
  return (
    <div className="fuel-wrap">
      <span>Fuel</span>
      <strong>{value}%</strong>
      <div className="fuel-track">
        <div className="fuel-fill" style={{ width: `${Math.max(0, Math.min(100, value))}%` }}></div>
      </div>
    </div>
  );
};

window.FuelBar = FuelBar;
