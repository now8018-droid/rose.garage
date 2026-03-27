const StatsSection = ({ car }) => {
  const rows = [
    { icon: 'solar:bag-4-bold', label: 'Kofferraum Lagerplatz', value: `${car.weight}kg` },
    { icon: 'solar:speedometer-bold', label: 'Top Speed Max Km/H', value: `${car.speed}km` },
    { icon: 'solar:box-bold', label: 'Car Type', value: car.className }
  ];

  return (
    <div className="stats-section">
      <div className="stat-row fuel-row">
        <div className="stat-icon"><iconify-icon icon="solar:fuel-bold"></iconify-icon></div>
        <window.FuelBar value={car.fuel} />
      </div>

      {rows.map((row) => (
        <div className="stat-row" key={row.label}>
          <div className="stat-icon"><iconify-icon icon={row.icon}></iconify-icon></div>
          <span>{row.label}</span>
          <strong>{row.value}</strong>
        </div>
      ))}
    </div>
  );
};

window.StatsSection = StatsSection;
