const SearchIcon = () => (
  <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15.5 14h-.79l-.28-.27a6.5 6.5 0 10-.71.71l.27.28v.79L20 21.5 21.5 20l-6-6zm-6 0A4.5 4.5 0 119.5 5a4.5 4.5 0 010 9z" /></svg>
);

export default function TopBar({ search, onSearchChange }) {
  return (
    <header className="topbar">
      <div className="brand-block">
        <span className="brand-accent">AURORA</span>
        <span className="brand-title">GARAGE</span>
      </div>

      <p className="helper-copy">Hier gibt es viel zu tun, räum deinen Dreck weg und vergiss nicht, die Rezepte zu überprüfen.</p>

      <div className="topbar-controls">
        <label className="search-box" htmlFor="carSearch">
          <SearchIcon />
          <input
            id="carSearch"
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Search car..."
          />
        </label>
        <button type="button" className="icon-btn amber" aria-label="Pin">P</button>
        <button type="button" className="icon-btn ghost" aria-label="Favorite">☆</button>
        <button type="button" className="icon-btn close" aria-label="Close">✕</button>
      </div>
    </header>
  );
}
