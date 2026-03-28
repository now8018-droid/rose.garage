(function () {
  'use strict';

  const { createApp, ref, reactive, computed, onMounted, onBeforeUnmount } = Vue;

  const RESOURCE_NAME = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'APEX-Garage';
  const clamp = (v) => Math.max(0, Math.min(100, Number(v) || 0));

  const postNui = async (endpoint, payload = {}) => {
    try {
      await fetch(`https://${RESOURCE_NAME}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload),
      });
    } catch (_err) {
      // Do not crash NUI in case callback endpoint is unavailable.
    }
  };

  createApp({
    components: {
      Sidebar: window.GarageSidebar,
      VehicleCard: window.VehicleCard,
      RenameModal: window.RenameModal,
    },
    setup() {
      const visible = ref(false);
      const garageType = ref('garage');
      const activeTab = ref('all');
      const search = ref('');
      const vehicles = ref([]);
      const busyPlate = ref('');
      const progress = ref(0);
      const renameModal = reactive({ show: false, plate: '', currentName: '', newName: '' });

      const favoriteSet = reactive(new Set(JSON.parse(localStorage.getItem('fav-list') || '[]')));

      let progressStart = 0;
      let progressDuration = 0;
      let rafId = 0;

      const updateProgress = () => {
        if (!busyPlate.value || progressDuration <= 0) return;
        const elapsed = performance.now() - progressStart;
        progress.value = clamp((elapsed / progressDuration) * 100);
        if (progress.value < 100) {
          rafId = requestAnimationFrame(updateProgress);
        }
      };

      const stopProgress = () => {
        busyPlate.value = '';
        progress.value = 0;
        progressDuration = 0;
        cancelAnimationFrame(rafId);
        rafId = 0;
      };

      const normalizeVehicles = (payload) => {
        const list = Object.values(payload && payload.data ? payload.data : {});
        return list.map((item) => {
          const stored = Boolean(item.stored);
          return {
            plate: item.plate || 'UNKNOWN',
            name: item.vehiclename || 'Unnamed Vehicle',
            className: item.class || 'UNKNOWN',
            fuel: clamp(item.fuel),
            engine: clamp(item.engine),
            image: `img/${item.img || 'model_car1'}.png`,
            status: stored ? 'garage' : 'pound',
            favorite: favoriteSet.has(item.plate),
          };
        });
      };

      const filteredVehicles = computed(() => {
        const q = search.value.trim().toLowerCase();
        return vehicles.value
          .filter((vehicle) => (activeTab.value === 'all' ? true : vehicle.status === activeTab.value))
          .filter((vehicle) => {
            if (!q) return true;
            return `${vehicle.name} ${vehicle.plate} ${vehicle.className}`.toLowerCase().includes(q);
          })
          .sort((a, b) => Number(b.favorite) - Number(a.favorite));
      });

      const closeUI = async () => {
        visible.value = false;
        renameModal.show = false;
        stopProgress();
        await postNui('exit', { plate: '' });
      };

      const toggleFavorite = (plate) => {
        if (!plate) return;
        if (favoriteSet.has(plate)) favoriteSet.delete(plate);
        else favoriteSet.add(plate);

        localStorage.setItem('fav-list', JSON.stringify(Array.from(favoriteSet)));
        vehicles.value = vehicles.value.map((v) => (v.plate === plate ? { ...v, favorite: favoriteSet.has(plate) } : v));
      };

      const onSpawn = async (plate) => {
        if (!plate || busyPlate.value) return;
        busyPlate.value = plate;
        progress.value = 1;
        await postNui('spawnvehicle', { plate });
      };

      const onTrunk = async (plate) => {
        if (!plate || busyPlate.value) return;
        await postNui('trunkopen', { plate });
      };

      const openRename = (vehicle) => {
        renameModal.show = true;
        renameModal.plate = vehicle.plate;
        renameModal.currentName = vehicle.name;
        renameModal.newName = vehicle.name;
      };

      const submitRename = async () => {
        const value = renameModal.newName.trim();
        if (value.length < 3 || value.length > 30) return;
        await postNui('changeName', { plate: renameModal.plate, rename: value });
        vehicles.value = vehicles.value.map((v) => (v.plate === renameModal.plate ? { ...v, name: value } : v));
        renameModal.show = false;
      };

      const handleMessage = (event) => {
        const data = event && event.data ? event.data : {};
        switch (data.action) {
          case 'open':
            visible.value = true;
            break;
          case 'closeui':
            visible.value = false;
            renameModal.show = false;
            stopProgress();
            break;
          case 'syncData':
            garageType.value = data.type || 'garage';
            activeTab.value = 'all';
            vehicles.value = normalizeVehicles(data);
            break;
          case 'spawnProgress':
            if (!data.show) {
              stopProgress();
              break;
            }
            busyPlate.value = data.plate || busyPlate.value;
            progressStart = performance.now();
            progressDuration = Math.max(1, Number(data.duration) || 0);
            progress.value = 0;
            cancelAnimationFrame(rafId);
            rafId = requestAnimationFrame(updateProgress);
            break;
          default:
            break;
        }
      };

      const onEscape = (e) => {
        if (!visible.value || e.key !== 'Escape') return;
        if (renameModal.show) renameModal.show = false;
        else closeUI();
      };

      onMounted(() => {
        window.addEventListener('message', handleMessage);
        window.addEventListener('keyup', onEscape);
      });

      onBeforeUnmount(() => {
        window.removeEventListener('message', handleMessage);
        window.removeEventListener('keyup', onEscape);
        stopProgress();
      });

      return {
        visible,
        garageType,
        activeTab,
        search,
        filteredVehicles,
        busyPlate,
        progress,
        renameModal,
        closeUI,
        onSpawn,
        onTrunk,
        openRename,
        submitRename,
        toggleFavorite,
      };
    },
    template: `
      <transition name="ui-fade">
        <main v-if="visible" class="garage-root">
          <Sidebar
            v-model:activeTab="activeTab"
            v-model:search="search"
            :visible-count="filteredVehicles.length"
            @close="closeUI"
          />

          <section class="content-panel">
            <header class="content-header">
              <h2>{{ garageType.toUpperCase() }}</h2>
              <p>เลือกเบิกยานพาหนะ หรือเปิดท้ายรถ</p>
            </header>

            <div class="grid">
              <VehicleCard
                v-for="vehicle in filteredVehicles"
                :key="vehicle.plate"
                :vehicle="vehicle"
                :busy-plate="busyPlate"
                :progress="progress"
                @spawn="onSpawn"
                @trunk="onTrunk"
                @rename="openRename"
                @toggle-favorite="toggleFavorite"
              />

              <div v-if="!filteredVehicles.length" class="empty-state glass">
                <iconify-icon icon="solar:inbox-line-outline"></iconify-icon>
                <p>ไม่พบยานพาหนะที่ตรงกับเงื่อนไข</p>
              </div>
            </div>
          </section>

          <RenameModal
            :show="renameModal.show"
            :vehicle-name="renameModal.currentName"
            :model-value="renameModal.newName"
            @update:modelValue="renameModal.newName = $event"
            @close="renameModal.show = false"
            @submit="submitRename"
          />
        </main>
      </transition>
    `,
  }).mount('#app');
})();
