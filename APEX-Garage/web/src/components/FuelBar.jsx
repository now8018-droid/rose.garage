export default function FuelBar({ value = 0 }) {
  return (
    <div className="fuel-row">
      <div className="fuel-copy">
        <small>Fuel</small>
        <strong>{value}%</strong>
      </div>
      <div className="fuel-bar">
        <span style={{ width: `${value}%` }} />
      </div>
    </div>
  );
}
