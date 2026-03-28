Config = Config or {}

-- ==============================
-- General
-- ==============================
Config.Debug = false
Config.SeeMarker = 25

-- ถ้าอยู่นอกระยะนี้ ระบบ garage จะพักการทำงานหนักไว้
Config.SystemWakeRadius = 80.0
Config.SystemWakeSleep = 1200

-- ==============================
-- Marker Colors
-- ==============================
Config.activeColor = { r = 255, g = 0, b = 0 }       -- จุดเก็บรถ
Config.activeColor2 = { r = 222, g = 222, b = 222 }  -- จุดเบิกรถ

Config.MarkerType = {
    car = 36,
    boat = 35,
    helicopter = 34,
}

-- ==============================
-- Dimension / Access
-- ==============================
Config.WhitelistDimen = { 100, 101 }  -- มิติที่อนุญาตให้ใช้งานลานจอดรถ
Config.DimensionsAllow = { 0, 100 }   -- มิติที่ต้องการเช็คสำหรับการใช้งาน Garage

-- ==============================
-- Economy / Vehicle State
-- ==============================
Config.poundCost = 3000

-- ลด Network Event ซ้ำ (มิลลิวินาที)
Config.RemoveDepositEventCooldown = 5000
Config.pounddeposit = true -- true = พาวรถจากจุดฝากได้
Config.healthPound = 100
Config.fuelPound = 100

-- เวลาโหลดตอนเบิกรถ (มิลลิวินาที)
Config.SpawnProgressDuration = 4000

-- ==============================
-- Spawn / Ghost
-- ==============================
-- ระยะ Ghost รอบจุดเบิกรถ (ใช้เป็นค่า default ถ้าจุดนั้นไม่ได้กำหนด GhostRadius)
Config.GhostRadius = 7.5

-- ระยะค้นหา/อัปเดตวง Ghost (ยิ่งน้อยยิ่งประหยัดทรัพยากร)
Config.GhostCheckRadius = 1

-- จังหวะอัปเดตระบบ Ghost (มิลลิวินาที)
Config.GhostLoopSleepNear = 350
Config.GhostLoopSleepFar = 1200
Config.GhostLoopSleepActive = 120

-- จังหวะสแกน marker หลัก (มิลลิวินาที)
Config.MarkerScanIntervalNear = 500
Config.MarkerScanIntervalFar = 2200

-- จังหวะสแกนเช็คว่าเข้าใกล้โซน garage หรือยัง (มิลลิวินาที)
Config.SystemWakeScanInterval = 1000

-- การวาด marker หน้าจอ (มิลลิวินาที + ระยะวาด)
Config.MarkerDrawDistance = 10.0
Config.MarkerDrawLoopSleepNear = 0
Config.MarkerDrawLoopSleepFar = 900


-- ==============================
-- Server Performance (oxmysql)
-- ==============================
Config.Performance = Config.Performance or {}

-- cache ระยะสั้นสำหรับข้อมูลรถตอนเปิด UI ซ้ำ ๆ
Config.Performance.ReloadCacheMs = 3000

-- batch flush สำหรับอัปเดตความเสียหายรถที่ยิงถี่
Config.Performance.DamageFlushIntervalMs = 1000

-- ==============================
-- Notification Hook
-- ==============================
Config.notification = function(type, text)
    -- type = 'success','error'
    -- text = 'ALERT TEXT'
    TriggerEvent('pNotify:SendNotification', {
        text = text,
        type = type,
        timeout = 8000,
    })
end
