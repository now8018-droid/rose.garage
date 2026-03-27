const TopBar = ({ title, search, onSearch, activeFilter, onFilter, onClose }) => {
  const filters = [
    { key: 'all', icon: 'solar:widget-bold' },
    { key: 'garage', icon: 'solar:garage-bold' },
    { key: 'pound', icon: 'solar:lock-keyhole-bold' }
  ];

  return (
    <header className="topbar">
      <div className="brand-wrap">
        <div className="logo-icon"><iconify-icon icon="solar:box-bold"></iconify-icon></div>
        <div className="brand-text">
          <h1><span>{title.toUpperCase()}</span> GARAGE</h1>
          <p>Hier gibt es viel zu tun, räum deinen Dreck weg und vergiss nicht, die Rezepte zu überprüfen.</p>
        </div>
      </div>

      <div className="top-controls">
        <div className="search-box">
          <iconify-icon icon="solar:magnifer-linear"></iconify-icon>
          <input value={search} onChange={(e) => onSearch(e.target.value)} placeholder="Search car..." />
        </div>

        {filters.map((filter) => (
          <button
            key={filter.key}
            className={`icon-btn ${activeFilter === filter.key ? 'active' : ''}`}
            onClick={() => onFilter(filter.key)}
          >
            <iconify-icon icon={filter.icon}></iconify-icon>
          </button>
        ))}

        <button className="icon-btn close-btn" onClick={onClose}>
          <iconify-icon icon="solar:close-square-linear"></iconify-icon>
        </button>
      </div>
    </header>
  );
};

window.TopBar = TopBar;
