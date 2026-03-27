(function () {
  const root = document.getElementById('root');
  const state = {
    visible: false,
    cars: [],
    garageType: 'garage',
    selectedPlate: '',
    query: '',
    filter: 'all',
    pounddeposit: false,
    spawnProgress: { show: false, duration: 0, plate: '', pct: 0 }
  };
  let progressTimer = null;

  const getResource = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'APEX-Garage');
  const post = (cb, payload) => fetch(`https://${getResource()}/${cb}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload || {})
  });
  const clamp = (n, min = 0, max = 100) => Math.max(min, Math.min(max, Number(n) || 0));

  function mappedCars() {
    return state.cars.map((car) => {
      let cardState = 'pound';
      if (state.pounddeposit) {
        if (car.stored && !car.deposit) cardState = 'garage';
      } else if (car.stored) cardState = 'garage';
      return Object.assign({}, car, { _state: cardState });
    });
  }

  function filteredCars() {
    return mappedCars().filter((car) => {
      if (state.filter !== 'all' && car._state !== state.filter) return false;
      if (!state.query) return true;
      return `${car.vehiclename || ''} ${car.plate || ''}`.toLowerCase().includes(state.query.toLowerCase());
    });
  }

  function selectCar() {
    const all = mappedCars();
    return all.find((c) => c.plate === state.selectedPlate) || filteredCars()[0] || null;
  }

  function card(car, selected) {
    const pct = state.spawnProgress.show && state.spawnProgress.plate === car.plate ? `<div class="progress">${state.spawnProgress.pct}%</div>` : '';
    return `<article class="car-card ${selected ? 'selected' : ''}" data-plate="${car.plate}">
      <span class="class">${car.class || 'Unknown'}</span>
      <button class="star" data-act="star">☆</button>
      <h3>${car.vehiclename || car.modelname || 'UNKNOWN'}</h3>
      <img src="img/${car.img}.png" alt="vehicle" onerror="this.src='img/model_car1.png'" />
      ${pct}
      <button class="select" data-act="spawn" data-plate="${car.plate}">• select car</button>
    </article>`;
  }

  function statRow(name, val, pct) {
    return `<div class="stat"><div><strong>${name}</strong><small>Some short information</small></div><div class="track"><span style="width:${clamp(pct)}%"></span></div><span class="chip">${val}</span></div>`;
  }

  function render() {
    if (!state.visible) {
      root.innerHTML = '';
      return;
    }
    const cars = filteredCars();
    if (!state.selectedPlate && cars[0]) state.selectedPlate = cars[0].plate;
    const selected = selectCar();

    root.innerHTML = `<div class="page"><div class="overlay-noise"></div><div class="layout">
      <section class="left-panel panel">
        <header class="top-row"><div><p class="eyebrow">• GARAGE</p><h1>TRACER<span class="muted">replay</span></h1></div><button class="close" data-act="exit">CLOSE ✕</button></header>
        <div class="toolbar"><div class="park-toggle">
          <button data-act="filter" data-filter="all" class="${state.filter === 'all' ? 'active' : ''}">All</button>
          <button data-act="filter" data-filter="garage" class="${state.filter === 'garage' ? 'active' : ''}">Parked</button>
          <button data-act="filter" data-filter="pound" class="${state.filter === 'pound' ? 'active' : ''}">Pound</button>
        </div><input id="search" placeholder="Search car..." value="${state.query}" /></div>
        <div class="grid">${cars.map((c) => card(c, selected && selected.plate === c.plate)).join('')}</div>
      </section>
      <aside class="right-panel panel">${selected ? `
        <p class="eyebrow">• Selected Car •</p>
        <h2>${selected.vehiclename || selected.modelname || 'UNKNOWN'} /</h2>
        <img class="hero" src="img/${selected.img}.png" alt="car" onerror="this.src='img/model_car2.png'" />
        <div class="plate">${selected.plate}</div>
        <div class="owner">Felx Haffner</div>
        <button class="share" data-act="send" data-plate="${selected.plate}">↗ Share Car</button>
        <div class="stats">
          ${statRow('Fuelstatus', `${clamp(selected.fuel)}L`, selected.fuel)}
          ${statRow('Trunkspace', '150 /500', 30)}
          ${statRow('Enginestatus', `${clamp(selected.engine)}%`, selected.engine)}
        </div>
        <div class="actions">
          <button data-act="trunk" data-plate="${selected.plate}">✕ Trunk Car</button>
          <button data-act="reload">◉ Fuel Car</button>
          <button data-act="spawn" data-plate="${selected.plate}">➤ Drive Car</button>
        </div>` : `<div class="empty">No vehicle data</div>`}
      </aside></div><div class="bg" data-type="${state.garageType}"></div></div>`;
  }

  document.addEventListener('click', (e) => {
    const actEl = e.target.closest('[data-act]');
    const cardEl = e.target.closest('.car-card');
    if (cardEl) {
      state.selectedPlate = cardEl.getAttribute('data-plate') || '';
      render();
    }
    if (!actEl) return;
    const act = actEl.getAttribute('data-act');
    const plate = actEl.getAttribute('data-plate') || '';
    if (act === 'exit') post('exit', { plate: '' });
    if (act === 'spawn') post('spawnvehicle', { plate });
    if (act === 'trunk') post('trunkopen', { plate });
    if (act === 'send') post('sendvehicle', { plate });
    if (act === 'reload') post('reloadVehicleData', {});
    if (act === 'filter') {
      state.filter = actEl.getAttribute('data-filter') || 'all';
      render();
    }
  });

  document.addEventListener('input', (e) => {
    if (e.target.id === 'search') {
      state.query = e.target.value || '';
      render();
    }
  });

  document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape' && state.visible) post('exit', { plate: '' });
  });

  window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') state.visible = true;
    if (data.action === 'closeui') {
      state.visible = false;
      state.spawnProgress = { show: false, duration: 0, plate: '', pct: 0 };
      if (progressTimer) { clearInterval(progressTimer); progressTimer = null; }
    }
    if (data.action === 'pounddeposit') state.pounddeposit = !!data.pounddeposit;
    if (data.action === 'syncData') {
      state.garageType = data.type || 'garage';
      state.cars = Array.isArray(data.data) ? data.data : [];
      if (!state.cars.some((c) => c.plate === state.selectedPlate)) {
        state.selectedPlate = state.cars[0] ? state.cars[0].plate : '';
      }
    }
    if (data.action === 'spawnProgress') {
      state.spawnProgress = { show: !!data.show, duration: Number(data.duration) || 0, plate: data.plate || '', pct: 0 };
      if (progressTimer) { clearInterval(progressTimer); progressTimer = null; }
      if (state.spawnProgress.show) {
        const started = Date.now();
        progressTimer = setInterval(() => {
          state.spawnProgress.pct = clamp(Math.floor(((Date.now() - started) / Math.max(1, state.spawnProgress.duration)) * 100));
          render();
          if (state.spawnProgress.pct >= 100) { clearInterval(progressTimer); progressTimer = null; }
        }, 50);
      }
    }
    render();
  });

  render();
})();
