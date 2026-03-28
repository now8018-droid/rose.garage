window.GarageSidebar = {
  name: 'GarageSidebar',
  props: {
    activeTab: { type: String, required: true },
    search: { type: String, required: true },
    visibleCount: { type: Number, required: true },
  },
  emits: ['update:activeTab', 'update:search', 'close'],
  data() {
    return {
      tabs: [
        { key: 'all', label: 'ทั้งหมด', icon: 'solar:widget-bold' },
        { key: 'garage', label: 'การาจ', icon: 'solar:garage-bold' },
        { key: 'pound', label: 'พาวน์', icon: 'solar:lock-keyhole-bold' },
      ],
    };
  },
  template: `
    <aside class="sidebar glass">
      <header class="sidebar-header">
        <div class="title-wrap">
          <iconify-icon icon="mingcute:car-3-fill"></iconify-icon>
          <div>
            <h1>ระบบเบิกยานพาหนะ</h1>
            <p>จำนวนที่แสดง {{ visibleCount }} คัน</p>
          </div>
        </div>
        <button class="ghost-btn" @click="$emit('close')" aria-label="close">
          <iconify-icon icon="solar:close-circle-bold"></iconify-icon>
        </button>
      </header>

      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="tab-btn"
          :class="{ active: activeTab === tab.key }"
          @click="$emit('update:activeTab', tab.key)"
        >
          <iconify-icon :icon="tab.icon"></iconify-icon>
          <span>{{ tab.label }}</span>
        </button>
      </div>

      <label class="search-box" aria-label="ค้นหา">
        <iconify-icon icon="solar:magnifer-linear"></iconify-icon>
        <input
          :value="search"
          @input="$emit('update:search', $event.target.value)"
          placeholder="ค้นหายานพาหนะ"
          maxlength="40"
        />
      </label>
    </aside>
  `,
};
