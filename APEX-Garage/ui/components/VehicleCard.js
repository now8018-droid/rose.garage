export default {
  name: 'VehicleCard',
  props: {
    vehicle: { type: Object, required: true },
    busyPlate: { type: String, default: '' },
    progress: { type: Number, default: 0 },
  },
  emits: ['spawn', 'trunk', 'rename', 'toggle-favorite'],
  computed: {
    isBusy() {
      return this.busyPlate && this.busyPlate === this.vehicle.plate;
    },
  },
  methods: {
    pct(value) {
      return `${Math.max(0, Math.min(100, Number(value) || 0))}%`;
    },
  },
  template: `
    <article class="vehicle-card glass" :class="[{ pound: vehicle.status === 'pound' }, { favorite: vehicle.favorite }]">
      <div class="card-cover">
        <img :src="vehicle.image" :alt="vehicle.name" loading="lazy" @error="$event.target.src = 'img/model_car1.png'"/>
      </div>

      <div class="card-main">
        <div class="title-row">
          <h3>{{ vehicle.name }}</h3>
          <button class="icon-btn" :class="{ active: vehicle.favorite }" @click="$emit('toggle-favorite', vehicle.plate)">
            <iconify-icon icon="solar:star-bold"></iconify-icon>
          </button>
        </div>

        <div class="meta-row">
          <span class="chip">{{ vehicle.plate }}</span>
          <span class="chip">{{ vehicle.className }}</span>
          <span v-if="vehicle.status === 'pound'" class="chip warning">พาวน์</span>
        </div>

        <div class="stat-list">
          <div class="stat-item">
            <span>เครื่องยนต์</span>
            <div class="bar"><div class="fill engine" :style="{ width: pct(vehicle.engine) }"></div></div>
            <b>{{ Math.round(vehicle.engine) }}</b>
          </div>
          <div class="stat-item">
            <span>น้ำมัน</span>
            <div class="bar"><div class="fill fuel" :style="{ width: pct(vehicle.fuel) }"></div></div>
            <b>{{ Math.round(vehicle.fuel) }}</b>
          </div>
        </div>

        <div v-if="isBusy" class="progress-overlay">
          <span>กำลังเบิก {{ progress }}%</span>
        </div>

        <div class="action-row">
          <button class="secondary" @click="$emit('trunk', vehicle.plate)" :disabled="isBusy || vehicle.status === 'pound'">
            <iconify-icon icon="solar:bag-4-bold"></iconify-icon> ท้ายรถ
          </button>
          <button class="secondary" @click="$emit('rename', vehicle)">
            <iconify-icon icon="solar:pen-bold"></iconify-icon> เปลี่ยนชื่อ
          </button>
          <button class="primary" @click="$emit('spawn', vehicle.plate)" :disabled="isBusy">
            <iconify-icon icon="solar:play-circle-bold"></iconify-icon> เบิกยานพาหนะ
          </button>
        </div>
      </div>
    </article>
  `,
};
