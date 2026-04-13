const app = document.getElementById('app');

const state = {
  visible: true,
  search: '',
  cars: Array.from({ length: 12 }, (_, i) => ({
    id: `car-${i + 1}`,
    name: 'PORSCHE GT4 RS',
    image: '../ui/img/model_car2.png',
    plate: `JJ12${600 + i}`,
    fuel: 100,
    weight: '50kg',
    topSpeed: '450km',
    type: 'Supersport'
  })),
  selectedCarId: 'car-1'
};

const postNui = (endpoint, payload) => {
  const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'APEX-Garage';
  return fetch(`https://${resourceName}/${endpoint}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload)
  });
};

function getFilteredCars() {
  if (!state.search) return state.cars;
  return state.cars.filter((car) => car.name.toLowerCase().includes(state.search.toLowerCase()));
}

function render() {
  const cars = getFilteredCars();
  const selected = cars.find((car) => car.id === state.selectedCarId) || cars[0];

  app.className = state.visible ? '' : 'hidden';
  app.innerHTML = `<main class="garage-root"><section class="garage-panel"><header class="topbar"><div class="brand-block"><span class="brand-accent">AURORA</span><span class="brand-title">GARAGE</span></div><p class="helper-copy">Hier gibt es viel zu tun, räum deinen Dreck weg und vergiss nicht, die Rezepte zu überprüfen.</p><div class="topbar-controls"><label class="search-box">🔍<input id="search" placeholder="Search car..." value="${state.search}"></label><button class="icon-btn amber">P</button><button class="icon-btn">☆</button><button class="icon-btn close" id="closeUi">✕</button></div></header><div class="garage-content"><section class="car-list">${cars.map((car) => `<article class="car-card ${car.id===selected?.id?'active':''}" data-id="${car.id}"><div class="car-card-header"><div><small>Car Name</small><h4>${car.name}</h4></div><button class="star-btn">☆</button></div><img src="${car.image}" class="car-thumb" alt="${car.name}"><button class="select-btn" data-id="${car.id}">Select</button></article>`).join('')}</section><aside class="detail-panel"><header class="detail-header"><small>Car Name</small><h3>${selected?.name || ''}</h3></header><img class="detail-image" src="${selected?.image || ''}" alt="car"><div class="plate-pill">${selected?.plate || ''}</div><div class="fuel-row"><div class="fuel-copy"><small>Fuel</small><strong>${selected?.fuel || 0}%</strong></div><div class="fuel-bar"><span style="width:${selected?.fuel || 0}%"></span></div></div><section class="stats-section"><div class="stat-row"><span class="stat-icon">📦</span><div class="stat-copy"><small>Kofferraum</small><strong>${selected?.weight || ''}</strong></div></div><div class="stat-row"><span class="stat-icon">⇧</span><div class="stat-copy"><small>Top Speed</small><strong>${selected?.topSpeed || ''}</strong></div></div><div class="stat-row"><span class="stat-icon">⬡</span><div class="stat-copy"><small>Car Type</small><strong>${selected?.type || ''}</strong></div></div></section><div class="action-buttons"><button data-action="tankCar">Tanken</button><button data-action="openTrunk">Kofferraum</button><button class="drive" data-action="driveCar">Drive Car</button></div></aside></div></section></main>`;

  document.querySelector('#search')?.addEventListener('input', (event) => {
    state.search = event.target.value;
    render();
  });

  document.querySelectorAll('.select-btn').forEach((button) => {
    button.addEventListener('click', () => {
      state.selectedCarId = button.dataset.id;
      postNui('selectCar', { carId: button.dataset.id }).catch(() => {});
      render();
    });
  });

  document.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', () => {
      if (!selected) return;
      postNui(button.dataset.action, { carId: selected.id, plate: selected.plate }).catch(() => {});
    });
  });

  document.querySelector('#closeUi')?.addEventListener('click', () => {
    state.visible = false;
    postNui('exit', {}).catch(() => {});
    render();
  });
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data?.type === 'openGarage') {
    state.visible = true;
    if (Array.isArray(data.cars) && data.cars.length > 0) {
      state.cars = data.cars;
      state.selectedCarId = data.cars[0].id;
    }
    render();
  }

  if (data?.type === 'closeGarage') {
    state.visible = false;
    render();
  }
});

render();
