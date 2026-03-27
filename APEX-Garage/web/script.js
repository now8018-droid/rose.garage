const state = {
  vehicles: [],
  selectedPlate: null,
  currentCategory: 'all',
  search: '',
  pounddeposit: false,
  favoriteOnly: false,
  fav: JSON.parse(localStorage.getItem('fav-list') || '[]'),
  uiOpen: false,
  garageType: 'garage',
  spawnLoading: false,
  spawnPlate: ''
};

const els = {
  shell: document.getElementById('garageShell'),
  title: document.getElementById('garageTitle'),
  grid: document.getElementById('carGrid'),
  searchInput: document.getElementById('searchInput'),
  closeBtn: document.getElementById('closeBtn'),
  favoriteFilterBtn: document.getElementById('favoriteFilterBtn'),
  detailName: document.getElementById('detailName'),
  detailImage: document.getElementById('detailImage'),
  detailPlate: document.getElementById('detailPlate'),
  detailClass: document.getElementById('detailClass'),
  detailStored: document.getElementById('detailStored'),
  fuelBar: document.getElementById('fuelBar'),
  fuelValue: document.getElementById('fuelValue'),
  engineBar: document.getElementById('engineBar'),
  engineValue: document.getElementById('engineValue'),
  spawnBtn: document.getElementById('spawnBtn'),
  trunkBtn: document.getElementById('trunkBtn'),
  renameBtn: document.getElementById('renameBtn'),
  sendBtn: document.getElementById('sendBtn'),
  detailFavoriteBtn: document.getElementById('detailFavoriteBtn')
};

function getResourceName() {
  try {
    if (typeof window.GetParentResourceName === 'function') {
      return window.GetParentResourceName();
    }
  } catch (_) {}
  return 'APEX-Garage';
}

async function postNui(endpoint, payload = {}) {
  const resource = getResourceName();
  const res = await fetch(`https://${resource}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  });

  try {
    return await res.json();
  } catch (_) {
    return null;
  }
}

function toggleFavorite(plate) {
  if (!plate) return;

  const idx = state.fav.indexOf(plate);
  if (idx >= 0) {
    state.fav.splice(idx, 1);
  } else {
    state.fav.push(plate);
  }

  localStorage.setItem('fav-list', JSON.stringify(state.fav));
  render();
}

function isFavorite(plate) {
  return state.fav.includes(plate);
}

function getVehicleState(vehicle) {
  let classMenu = 'pound';
  if (state.pounddeposit) {
    if (vehicle.stored && !vehicle.deposit) classMenu = 'garage';
  } else if (vehicle.stored) {
    classMenu = 'garage';
  }
  return classMenu;
}

function filteredVehicles() {
  return state.vehicles.filter((vehicle) => {
    const bucket = getVehicleState(vehicle);
    const matchCategory = state.currentCategory === 'all' || bucket === state.currentCategory;
    const matchSearch = (vehicle.vehiclename || '').toLowerCase().includes(state.search.toLowerCase());
    const matchFavorite = !state.favoriteOnly || isFavorite(vehicle.plate);
    return matchCategory && matchSearch && matchFavorite;
  });
}

function selectVehicle(plate) {
  state.selectedPlate = plate;
  renderDetail();
  renderGrid();
}

function selectedVehicle() {
  if (!state.vehicles.length) return null;
  const found = state.vehicles.find((v) => v.plate === state.selectedPlate);
  return found || state.vehicles[0];
}

function toPct(value) {
  const n = Number(value) || 0;
  return Math.max(0, Math.min(100, Math.round(n)));
}

function renderGrid() {
  const list = filteredVehicles();

  if (!list.length) {
    els.grid.innerHTML = '<article class="car-card"><span class="name">NO VEHICLE</span></article>';
    return;
  }

  els.grid.innerHTML = list.map((car) => {
    const selected = car.plate === selectedVehicle()?.plate;
    const fav = isFavorite(car.plate);
    const bucket = getVehicleState(car);
    const disabled = state.spawnLoading && state.spawnPlate && state.spawnPlate !== car.plate;

    return `
      <article class="car-card ${selected ? 'is-selected' : ''} ${disabled ? 'is-disabled' : ''}" data-plate="${car.plate}">
        <span class="label">${car.class || 'UNKNOWN'} • ${bucket.toUpperCase()}</span>
        <span class="name">${car.vehiclename || 'UNKNOWN'}</span>
        <button class="star fav-toggle" data-plate="${car.plate}">${fav ? '★' : '☆'}</button>
        <img src="img/${car.img || 'cars'}.png" alt="${car.vehiclename || car.plate}" onerror="this.src='img/cars.png'" />
        <button class="select-btn ${selected ? 'active' : ''}" data-plate="${car.plate}" ${disabled ? 'disabled' : ''}>↘ select car</button>
      </article>
    `;
  }).join('');
}

function renderDetail() {
  const car = selectedVehicle();
  if (!car) {
    els.detailName.textContent = 'No Vehicle';
    els.detailPlate.textContent = '-';
    return;
  }

  state.selectedPlate = car.plate;

  const fuel = toPct(car.fuel);
  const engine = toPct(car.engine);
  const carState = getVehicleState(car);

  els.detailName.textContent = `${car.vehiclename || 'UNKNOWN'} /`;
  els.detailImage.src = `img/${car.img || 'cars'}.png`;
  els.detailPlate.textContent = car.plate || '-';
  els.detailClass.textContent = car.class || '-';
  els.detailStored.textContent = carState.toUpperCase();
  els.fuelBar.style.width = `${fuel}%`;
  els.fuelValue.textContent = `${fuel}%`;
  els.engineBar.style.width = `${engine}%`;
  els.engineValue.textContent = `${engine}%`;
  els.detailFavoriteBtn.textContent = isFavorite(car.plate) ? '★' : '☆';

  els.spawnBtn.disabled = state.spawnLoading;
  els.trunkBtn.disabled = state.spawnLoading || state.garageType === 'pound';
  els.sendBtn.disabled = state.spawnLoading;
  els.renameBtn.disabled = state.spawnLoading || state.garageType === 'pound';
}

function renderCategoryButtons() {
  document.querySelectorAll('.category-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.menu === state.currentCategory);
  });

  els.favoriteFilterBtn.classList.toggle('active', state.favoriteOnly);
}

function render() {
  if (!state.selectedPlate && state.vehicles.length) {
    state.selectedPlate = state.vehicles[0].plate;
  }
  renderCategoryButtons();
  renderGrid();
  renderDetail();
}

function closeUi() {
  state.uiOpen = false;
  els.shell.style.display = 'none';
  state.spawnLoading = false;
  state.spawnPlate = '';
}

async function spawnVehicle() {
  const car = selectedVehicle();
  if (!car || state.spawnLoading) return;

  state.spawnLoading = true;
  state.spawnPlate = car.plate;
  render();

  await postNui('spawnvehicle', { plate: car.plate });

  setTimeout(() => {
    state.spawnLoading = false;
    state.spawnPlate = '';
    render();
  }, 500);
}

async function openTrunk() {
  const car = selectedVehicle();
  if (!car || state.spawnLoading || state.garageType === 'pound') return;
  await postNui('trunkopen', { plate: car.plate });
}

async function sendVehicle() {
  const car = selectedVehicle();
  if (!car || state.spawnLoading) return;
  await postNui('sendvehicle', { plate: car.plate });
}

async function renameVehicle() {
  const car = selectedVehicle();
  if (!car || state.spawnLoading || state.garageType === 'pound') return;

  const rename = window.prompt('ตั้งชื่อใหม่รถคันนี้', car.vehiclename || '');
  if (!rename) return;

  await postNui('changeName', { plate: car.plate, rename });
}

els.searchInput.addEventListener('input', (e) => {
  state.search = e.target.value || '';
  renderGrid();
});

els.closeBtn.addEventListener('click', async () => {
  closeUi();
  await postNui('exit', { plate: '' });
});

els.favoriteFilterBtn.addEventListener('click', () => {
  state.favoriteOnly = !state.favoriteOnly;
  render();
});

document.querySelectorAll('.category-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    state.currentCategory = btn.dataset.menu;
    render();
  });
});

els.spawnBtn.addEventListener('click', spawnVehicle);
els.trunkBtn.addEventListener('click', openTrunk);
els.sendBtn.addEventListener('click', sendVehicle);
els.renameBtn.addEventListener('click', renameVehicle);
els.detailFavoriteBtn.addEventListener('click', () => toggleFavorite(state.selectedPlate));

els.grid.addEventListener('click', (e) => {
  const target = e.target;
  const plate = target.dataset.plate || target.closest('[data-plate]')?.dataset.plate;
  if (!plate) return;

  if (target.classList.contains('fav-toggle')) {
    toggleFavorite(plate);
    return;
  }

  selectVehicle(plate);
});

document.addEventListener('keyup', async (event) => {
  if (event.key === 'Escape' && state.uiOpen) {
    closeUi();
    await postNui('exit', { plate: '' });
  }
});

window.addEventListener('message', (event) => {
  const data = event.data || {};

  if (data.action === 'open') {
    state.uiOpen = true;
    els.shell.style.display = 'flex';
    return;
  }

  if (data.action === 'closeui') {
    closeUi();
    return;
  }

  if (data.action === 'pounddeposit') {
    state.pounddeposit = !!data.pounddeposit;
    return;
  }

  if (data.action === 'spawnProgress') {
    state.spawnLoading = !!data.show;
    state.spawnPlate = data.plate || state.spawnPlate;
    render();
    return;
  }

  if (data.action === 'syncData') {
    state.vehicles = Array.isArray(data.data) ? data.data : [];
    state.garageType = data.type || 'garage';
    els.title.textContent = String(state.garageType || 'garage').toUpperCase();
    state.currentCategory = 'all';
    state.selectedPlate = state.vehicles[0]?.plate || null;
    render();
  }
});
