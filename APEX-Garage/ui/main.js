// ============================================
// VAL GARAGE - MAIN JAVASCRIPT
// Modern UI with Smooth Animations
// ============================================

// State Variables
let detailDisplay = false;
let renameDisplay = false;
let fav = JSON.parse(localStorage.getItem("fav-list")) || [];
let favSelect = false;
let canClick = true;
let nowPlateEdit = '';
let pounddeposit = false;
let nowGarage = '';
let isSpawnLoading = false;
let activeSpawnPlate = '';
let spawnProgressInterval = null;
let selectedVehiclePlate = '';

// ============================================
// HELPER FUNCTIONS
// ============================================

function GetParentResourceName() {
    return 'APEX-Garage';
}

function getPosition(element) {
    const rect = element.getBoundingClientRect();
    return { x: rect.left, y: rect.top };
}

function disableselect(e) {
    return false;
}

function reEnable() {
    return true;
}

// Prevent text selection
document.onselectstart = () => false;
if (window.sidebar) {
    document.onmousedown = disableselect;
    document.onclick = reEnable;
}

// ============================================
// SEARCH FUNCTIONALITY
// ============================================

document.querySelector('#search').addEventListener('input', filterList);

function filterList() {
    const searchInput = document.querySelector("#search");
    const filter = searchInput.value.toLowerCase();
    const listItems = document.querySelectorAll('.car_box');

    listItems.forEach((item) => {
        if (item.classList.contains('empty_block')) return;
        
        const text = item.querySelector('.car_name')?.textContent || '';
        const shouldShow = text.toLowerCase().includes(filter);
        
        item.style.display = shouldShow ? '' : 'none';
    });
}

// ============================================
// UI CLOSE FUNCTION
// ============================================

function UICLOSE() {
    const garage = document.querySelector('.assist_garage');
    garage.style.display = 'none';
    setSpawnProgress(false, 0, '');
}

// ============================================
// NOTIFICATION FUNCTION (disabled UI)
// ============================================

function notishow() {}

// ============================================
// UPDATE VEHICLE COUNT
// ============================================


function setSpawnProgress(show, duration = 0, plate = '') {
    const allProgress = document.querySelectorAll('.spawn-progress-inline');
    const allCarBoxes = document.querySelectorAll('.car_box');
    const vehicleCarBoxes = document.querySelectorAll('.car_box[data-plate]');

    allProgress.forEach((el) => {
        el.style.display = 'none';
    });
    allCarBoxes.forEach((car) => {
        car.classList.remove('spawn-loading-active', 'spawn-loading-dimmed');
    });

    if (spawnProgressInterval) {
        clearInterval(spawnProgressInterval);
        spawnProgressInterval = null;
    }

    if (!show) {
        isSpawnLoading = false;
        activeSpawnPlate = '';
        document.body.classList.remove('garage-loading');
        allProgress.forEach((el) => {
            const txt = el.querySelector('.spawn-progress-text');
            if (txt) txt.textContent = '0%';
        });
        return;
    }

    isSpawnLoading = true;
    activeSpawnPlate = plate || activeSpawnPlate;
    document.body.classList.add('garage-loading');

    const target = activeSpawnPlate ? document.querySelector(`.car_box[data-plate="${activeSpawnPlate}"] .spawn-progress-inline`) : null;
    if (!target) return;

    target.style.display = 'flex';
    const targetCarBox = target.closest('.car_box');
    if (targetCarBox) {
        targetCarBox.classList.add('spawn-loading-active');
        vehicleCarBoxes.forEach((car) => {
            if (car !== targetCarBox) car.classList.add('spawn-loading-dimmed');
        });
    }
    const text = target.querySelector('.spawn-progress-text');
    if (!text) return;

    const total = Math.max(1, Number(duration) || 0);
    const start = Date.now();
    text.textContent = '0%';

    spawnProgressInterval = setInterval(() => {
        const elapsed = Date.now() - start;
        const progress = Math.min(100, Math.floor((elapsed / total) * 100));
        text.textContent = `${progress}%`;
        if (progress >= 100) {
            clearInterval(spawnProgressInterval);
            spawnProgressInterval = null;
        }
    }, 50);
}

function updateVehicleCount(count) {
    const countEl = document.getElementById('vehicle-count');
    if (countEl) {
        countEl.textContent = count;
    }
}

function updateSelectedPanel(cardEl) {
    if (!cardEl) return;

    document.querySelectorAll('.car_box').forEach((card) => {
        card.classList.remove('car_selected');
    });
    cardEl.classList.add('car_selected');

    const name = cardEl.getAttribute('data-vehiclename') || 'Unknown Vehicle';
    const plate = cardEl.getAttribute('data-plate') || '-';
    const className = cardEl.querySelector('.tag.class')?.textContent?.trim() || '-';
    const fuel = Number(cardEl.getAttribute('data-fuel') || 0);
    const engine = Number(cardEl.getAttribute('data-engine') || 0);
    const imageSrc = cardEl.querySelector('.car_img img')?.getAttribute('src') || './img/sultan2.png';

    const setText = (id, value) => {
        const el = document.getElementById(id);
        if (el) el.textContent = value;
    };

    setText('selected-name', name);
    setText('selected-plate', plate);
    setText('selected-class', className);
    setText('selected-fuel', `${Math.round(fuel)}%`);
    setText('selected-engine', `${Math.round(engine)}%`);

    const imageEl = document.getElementById('selected-image');
    if (imageEl) imageEl.src = imageSrc;

    const fuelBar = document.getElementById('selected-fuel-bar');
    const engineBar = document.getElementById('selected-engine-bar');
    if (fuelBar) fuelBar.style.width = `${Math.max(0, Math.min(100, fuel))}%`;
    if (engineBar) engineBar.style.width = `${Math.max(0, Math.min(100, engine))}%`;

    selectedVehiclePlate = plate;
}

// ============================================
// EVENT LISTENERS - jQuery
// ============================================

// Container click - close detail
$('body').on('click', '.container', function () {
    if (detailDisplay) {
        detailDisplay = false;
        $('.car-list').removeClass('active');
        $('.add-detail').hide();
    }
});

// Scroll - close detail
$('.car-strage').on('scroll', function () {
    if (detailDisplay) {
        detailDisplay = false;
        $('.car-list').removeClass('active');
        $('.add-detail').hide();
    }
});

// Trunk Button
$('body').on('click', '.vehicle-detail2', function (e) {
    e.stopPropagation();
    if (isSpawnLoading || !canClick) return;
    
    canClick = false;
    const plate = $(this).closest('.car_box').attr('data-plate');
    
    // Add click animation
    $(this).css('transform', 'scale(0.9)');
    setTimeout(() => $(this).css('transform', ''), 150);
    
    $.post(`https://${GetParentResourceName()}/trunkopen`, JSON.stringify({
        plate: plate
    }), function (cb) {
        if (cb === 'success') {
            UICLOSE();
            detailDisplay = false;
        } else {
            notishow('Cannot open trunk for this vehicle');
        }
    });
    
    setTimeout(() => { canClick = true; }, 400);
});

// Spawn Button
$('body').on('click', '.spawn', function (e) {
    e.stopPropagation();
    if (isSpawnLoading || !canClick) return;
    
    canClick = false;
    const plate = $(this).closest('.car_box').attr('data-plate');
    
    // Add click animation
    $(this).css('transform', 'scale(0.95)');
    setTimeout(() => $(this).css('transform', ''), 150);
    
    $.post(`https://${GetParentResourceName()}/spawnvehicle`, JSON.stringify({
        plate: plate
    }), function (cb) {
        if (cb === 'success') {
            $('.add-detail').fadeOut();
            detailDisplay = false;
        } else {
            notishow('Insufficient funds for pound');
        }
    });
    
    setTimeout(() => { canClick = true; }, 400);
});

$('body').on('click', '.car_box[data-plate]', function () {
    updateSelectedPanel(this);
});

// Edit/Rename
$('body').on('click', '.edit', function () {
    if (renameDisplay || !canClick) return;
    
    canClick = false;
    renameDisplay = true;
    nowPlateEdit = $(this).attr('data-plate-rename');
    const currentName = $(this).attr('data-vehiclename') || '';
    $('#name-input').val(currentName);
    $('.car-list').removeClass('active');
    $('.add-detail').hide();
    detailDisplay = false;
    $('.display-input').css('display', 'flex').hide().fadeIn();
    
    setTimeout(() => { canClick = true; }, 400);
});

// Exit Area
$('body').on('click', '.exit-area', function () {
    if (isSpawnLoading) return;
    if (renameDisplay) {
        renameDisplay = false;
        $('.display-input').fadeOut();
    } else if (detailDisplay) {
        detailDisplay = false;
        $('.car-list').removeClass('active');
        $('.add-detail').hide();
    } else {
        UICLOSE();
        $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({
            plate: $(this).attr('data-plate-spawn')
        }));
    }
});

$('body').on('click', '#panel-open-trunk', function () {
    if (!selectedVehiclePlate || isSpawnLoading || !canClick) return;
    const target = $(`.car_box[data-plate="${selectedVehiclePlate}"] .vehicle-detail2`).first();
    if (target.length) target.trigger('click');
});

$('body').on('click', '#panel-spawn', function () {
    if (!selectedVehiclePlate || isSpawnLoading || !canClick) return;
    const target = $(`.car_box[data-plate="${selectedVehiclePlate}"] .spawn`).first();
    if (target.length) target.trigger('click');
});

// Submit Rename
$('body').on('click', '.submit-btn', function () {
    const value = document.getElementById('name-input').value;
    
    if (value.length <= 2) {
        notishow('Name is too short');
    } else if (value.length > 30) {
        notishow('Name is too long');
    } else {
        renameDisplay = false;
        $('.display-input').fadeOut();
        $.post(`https://${GetParentResourceName()}/changeName`, JSON.stringify({
            plate: nowPlateEdit,
            rename: $('#name-input').val()
        }));
        $('#name-input').val('');
    }
});

// Send Vehicle
$('body').on('click', '.send', function () {
    if (!canClick) return;
    
    canClick = false;
    $.post(`https://${GetParentResourceName()}/sendvehicle`, JSON.stringify({
        plate: $(this).attr('data-plate-send')
    }), function (cb) {
        if (cb === 'success') {
            $('.car-list').removeClass('active');
            $('.add-detail').fadeOut();
            detailDisplay = false;
        } else {
            notishow('');
        }
    });
    
    setTimeout(() => { canClick = true; }, 400);
});

// Favorite Button
$('body').on('click', '.fav-btn', function (e) {
    e.stopPropagation();
    const carBox = $(this).closest('.car_box');
    const plateFav = $(this).attr('data-plate-fav');
    
    // Add animation
    $(this).css('transform', 'scale(1.2)');
    setTimeout(() => $(this).css('transform', ''), 200);
    
    if (carBox.hasClass('favorite')) {
        carBox.removeClass('favorite');
        const index = fav.indexOf(plateFav);
        if (index > -1) fav.splice(index, 1);
        carBox.css('order', '2');
    } else {
        carBox.addClass('favorite');
        if (!fav.includes(plateFav)) fav.push(plateFav);
        carBox.css('order', '1');
    }
    
    localStorage.setItem("fav-list", JSON.stringify(fav));
});

// Category Tabs
$('body').on('click', '.category', function () {
    if (isSpawnLoading) return;
    const typemenu = $(this).attr('data-menu');
    
    // Update active state
    $('.category').removeClass('select_category');
    $(this).addClass('select_category');
    
    // Filter vehicles
    if (typemenu === 'all') {
        $('.car_box').each(function() {
            const $this = $(this);
            if ($this.hasClass('empty_block') && ($this.hasClass('garage') || $this.hasClass('pound'))) {
                $this.hide();
            } else {
                $this.show();
            }
        });
    } else {
        $('.car_box').hide();
        $(`.car_box.${typemenu}`).show();
    }
});

// ============================================
// KEYBOARD EVENTS
// ============================================

document.onkeyup = function (data) {
    if (isSpawnLoading) return;
    if (data.which === 27) { // ESC key
        if (renameDisplay) {
            $('.display-input').fadeOut(300);
            renameDisplay = false;
        } else if (detailDisplay) {
            detailDisplay = false;
            $('.car-list').removeClass('active');
            $('.add-detail').hide();
        } else {
            UICLOSE();
            $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({
                plate: ''
            }));
        }
    }
};

// ============================================
// MESSAGE EVENT LISTENER
// ============================================

window.addEventListener('message', function (event) {
    const data = event.data;
    
    // Open UI
    if (data.action === 'open') {
        const garage = document.querySelector('.assist_garage');
        garage.style.display = 'flex';
    }
    
    // Close UI
    if (data.action === 'closeui') {
        UICLOSE();
        detailDisplay = false;
    }
    
    // Pound Deposit Setting
    if (data.action === 'pounddeposit') {
        pounddeposit = data.pounddeposit;
    }
    
    // Sync Vehicle Data
    if (data.action === 'syncData') {
        syncVehicleData(data);
    }

    if (data.action === 'spawnProgress') {
        setSpawnProgress(data.show, data.duration, data.plate || activeSpawnPlate);
    }
});

// ============================================
// SYNC VEHICLE DATA
// ============================================

function syncVehicleData(eventData) {
    const content = document.querySelector('.assist_content');
    content.innerHTML = '';
    
    // Reset categories
    $('.category').removeClass('select_category');
    $('.category:first').addClass('select_category');
    
    nowGarage = eventData.type;
    let allVehicle = 0;
    let garageCount = 0;
    let poundCount = 0;
    
    // Update title
    document.getElementById('title-garage').textContent = nowGarage.toUpperCase();
    
    // Build trunk button HTML
    const trunkHTML = nowGarage !== 'pound' ? `
        <div class="button_trunk vehicle-detail2">
            <iconify-icon icon="solar:bag-4-bold"></iconify-icon>
            <span class="btn-tooltip">ท้ายรถ</span>
        </div>
    ` : '';

    
    // Process each vehicle
    for (const key in eventData.data) {
        allVehicle++;
        const vehicle = eventData.data[key];
        
        let fuel = vehicle.fuel ? vehicle.fuel.toFixed(0) : 0;
        let engine = vehicle.engine ? vehicle.engine.toFixed(0) : 0;
        let classMenu = 'pound';
        let textNotAction = 'การาจ';
        
        if (nowGarage === 'garage') {
            textNotAction = vehicle.deposit ? `จุดฝากรถ ${vehicle.deposit}` : 'พาวน์';
        }
        
        // Determine vehicle status
        if (pounddeposit) {
            if (vehicle.stored) {
                if (vehicle.deposit) {
                    poundCount++;
                } else {
                    classMenu = 'garage';
                    garageCount++;
                }
            } else {
                poundCount++;
            }
        } else {
            if (vehicle.stored) {
                classMenu = 'garage';
                garageCount++;
                if (vehicle.deposit) {
                    textNotAction = `DEPOSIT ${vehicle.deposit}`;
                }
            } else {
                poundCount++;
            }
        }
        
        // Check favorite status
        let nowFav = '';
        let order = 2;
        if (fav && fav.includes(vehicle.plate)) {
            nowFav = 'favorite';
            order = 1;
        }
        
        const renameHTML = nowGarage !== 'pound' ? `
            <div class="button_rename edit" data-plate-rename="${vehicle.plate}" data-vehiclename="${vehicle.vehiclename}">
                <iconify-icon icon="solar:pen-bold"></iconify-icon>
                <span class="btn-tooltip">เปลี่ยนชื่อ</span>
            </div>
        ` : '';

        // Calculate stat bar widths
        const engineWidth = Math.min(100, Math.max(0, engine));
        const fuelWidth = Math.min(100, Math.max(0, fuel));
        
        // Create vehicle card HTML
        const cardHTML = `
            <div class="car_box ${nowFav} ${classMenu}" 
                 style="order:${order}" 
                 data-fav="${nowFav}" 
                 data-plate="${vehicle.plate}" 
                 data-vehiclename="${vehicle.vehiclename}" 
                 data-fuel="${fuel}" 
                 data-engine="${engine}"
                 data-speed="${vehicle.maxspeed || 0}" 
                 data-acc="${vehicle.maxacc || 0}" 
                 data-break="${vehicle.maxbreak || 0}" 
                 data-weight="${vehicle.weight || 0}">
                
                <div class="card-glow"></div>
                <div class="spawn-progress-inline">
                    <div class="spawn-progress-loader" aria-hidden="true">
                        <span></span><span></span><span></span><span></span><span></span><span></span>
                        <span></span><span></span><span></span><span></span><span></span><span></span>
                    </div>
                    <div class="spawn-progress-text">0%</div>
                </div>
                
                <div class="assist_pound">
                    <div class="pound-content">
                        <iconify-icon icon="solar:shield-warning-bold"></iconify-icon>
                        <p>ยานพาหนะนี้อยู่ใน ${textNotAction.toUpperCase()}</p>
                    </div>
                </div>

                <div class="card-top">
                    <div class="mini-class">${vehicle.class || 'SUPER SPORT'}</div>
                    <div class="assist_favorite_btn fav-btn" data-plate-fav="${vehicle.plate}">
                        <iconify-icon icon="solar:star-bold"></iconify-icon>
                    </div>
                </div>

                <div class="car_center">
                    <div class="car_name">
                        <h4>${(vehicle.class || 'Super Sport')}</h4>
                        <h3>${vehicle.vehiclename}</h3>
                        <div class="car_tags hidden-meta">
                            <span class="tag plate">${vehicle.plate}</span>
                            <span class="tag class">${vehicle.class || 'UNKNOWN'}</span>
                        </div>
                    </div>
                </div>

                <div class="car_left">
                    <div class="car_img">
                        <img src="img/${vehicle.img}.png" alt="${vehicle.vehiclename}" onerror="this.src='img/unknow.png'">
                        <div class="img-overlay"></div>
                    </div>
                </div>

                <div class="car_right">
                    <div class="car_console">
                        ${trunkHTML}
                        ${renameHTML}
                        <div class="button_spawn spawn">
                            <iconify-icon icon="solar:play-circle-bold"></iconify-icon>
                            <span>select car</span>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        content.insertAdjacentHTML('beforeend', cardHTML);
    }
    
    // Update vehicle count
    updateVehicleCount(allVehicle);
    
    // Add empty blocks
    const emptyBlockHTML = `
        <div class="car_box empty_block" style="order: 4">
            <div class="empty-content">
                <iconify-icon icon="solar:add-circle-linear" class="empty_icon"></iconify-icon>
                <span>ว่างเปล่า</span>
            </div>
        </div>
    `;
    
    // Add empty blocks for all view
    const emptyCount = Math.max(0, 5 - allVehicle);
    for (let i = 0; i < emptyCount; i++) {
        content.insertAdjacentHTML('beforeend', emptyBlockHTML);
    }
    
    // Add empty blocks for garage view
    const garageEmptyCount = Math.max(0, 5 - garageCount);
    for (let i = 0; i < garageEmptyCount; i++) {
        content.insertAdjacentHTML('beforeend', 
            emptyBlockHTML.replace('empty_block', 'empty_block garage').replace('style="order: 4"', 'style="order: 4; display: none;"')
        );
    }
    
    // Add empty blocks for pound view
    const poundEmptyCount = Math.max(0, 5 - poundCount);
    for (let i = 0; i < poundEmptyCount; i++) {
        content.insertAdjacentHTML('beforeend', 
            emptyBlockHTML.replace('empty_block', 'empty_block pound').replace('style="order: 4"', 'style="order: 4; display: none;"')
        );
    }
    
    // Set pound status based on garage type
    if (nowGarage === 'garage') {
        $('.car_box.garage').removeClass('car_inpound');
        $('.car_box.pound').addClass('car_inpound').css('order', '3');
    } else {
        $('.car_box.pound').removeClass('car_inpound');
        $('.car_box.garage').addClass('car_inpound').css('order', '3');
    }

    const firstCard = document.querySelector('.car_box[data-plate]');
    if (firstCard) {
        updateSelectedPanel(firstCard);
    } else {
        selectedVehiclePlate = '';
        const selectedName = document.getElementById('selected-name');
        if (selectedName) selectedName.textContent = 'No Vehicle Selected';
    }
}

// ============================================
// INITIALIZATION
// ============================================

$(document).ready(function() {
    // Initialize favorites from localStorage
    fav = JSON.parse(localStorage.getItem("fav-list")) || [];
});
