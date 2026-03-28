window.RenameModal = {
  name: 'RenameModal',
  props: {
    show: { type: Boolean, required: true },
    modelValue: { type: String, required: true },
    vehicleName: { type: String, default: '' },
  },
  emits: ['update:modelValue', 'close', 'submit'],
  template: `
    <transition name="modal-fade">
      <div v-if="show" class="modal-backdrop" @click.self="$emit('close')">
        <section class="modal-card glass" role="dialog" aria-modal="true">
          <h3>เปลี่ยนชื่อยานพาหนะ</h3>
          <p>คันปัจจุบัน: {{ vehicleName }}</p>
          <input
            :value="modelValue"
            @input="$emit('update:modelValue', $event.target.value)"
            maxlength="30"
            placeholder="ตั้งชื่อใหม่"
            autofocus
          />
          <div class="modal-actions">
            <button class="secondary" @click="$emit('close')">ยกเลิก</button>
            <button class="primary" @click="$emit('submit')">บันทึก</button>
          </div>
        </section>
      </div>
    </transition>
  `,
};
