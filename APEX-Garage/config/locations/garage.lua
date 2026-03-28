Config = Config or {}

-- =========================================================
-- Garage Location Config
-- =========================================================
-- หมายเหตุฟิลด์ที่ใช้บ่อย:
--   name / labelname  : รหัสและชื่อการาจ
--   location          : จุดกดเปิดเมนูเบิกรถ
--   spawnlocation     : จุดสปอนรถ
--   spawnheading      : หัวรถตอนสปอน
--   deletelocation    : จุดเก็บรถ
--   Radius / DelRadius: ระยะใช้งาน marker
--   vehicletype       : car | boat | helicopter
--   job               : string หรือ table ของ job ที่อนุญาต
--   Propspawn         : prop จุดเบิก
--   Propdelete        : prop จุดเก็บ

Config.SpawnMarker = {
    type = 36,
    r = 94, g = 180, b = 191, a = 100,
    x = 1.85, y = 1.5, z = 1.2
} -- Marker จุดเบิกรถ

Config.DeleteMarker = {
    type = 6,
    r = 255, g = 51, b = 51, a = 100,
    x = 4.0, y = 4.0, z = 0.30
} -- Marker จุดเก็บรถ (HorizontalSplitArrowCircle)

-- Config.DeleteMarker2 = { type = 36, r = 255, g = 51, b = 51, a = 100, x = 1.7, y = 1.7, z = 1.2 }

-- job = { 'police', 'ambulance', 'council' } ถ้าใส่ จะให้เฉพาะคนที่มี job ใช้งานได้
-- deletelocation ไม่ใส่ก็ได้
-- vehicletype = 'car' | 'boat' | 'helicopter'
Config.garageDetail = {

    -- {   
    --     name        = 'event_garage',                                              ------------------------------ ชื่อการาจใน DATA [ห้ามตัวพิมพ์ใหญ่ / ห้ามเว้นวรรค / ห้ามตั้งชื่อยาว / ถ้าจะเว้นให้ใช้ _ แทน]
    --     labelname   = 'EVENT GARAGE',                                          ------------------------------ ชื่อการาจที่แสดง
    --     location    = vector3(-1469.344, -1487.731, 2.0722439),              ------------------------------ จุดเบิกรถ
    --     spawnlocation = vector3(-1456.014, -1474.749, 2.0722439),            ------------------------------ จุด Spawn รถ
    --     spawnheading  = 325.55117,                                              ------------------------------ ทิศทางหน้ารถ
    --     vehicletype   = 'car',
    --     deletelocation = vector3(-1480.627, -1469.665, 2.2769656),           ------------------------------ จุดเก็บรถ

    --     Propspawn = {
    --         model   = "un_bendix_prop_garage_assist",
    --         heading = 147.17845                                             ------------------------------ ทิศทาง Prop เบิกรถ
    --     },
    --     Propdelete = { 
    --         model   = "un_bendix_prop_deposit_assist",
    --         heading = 136.97219                                                  ------------------------------ ทิศทาง Prop เก็บรถ
    --     }
    -- },

    {   
        name        = 'yl_garage',                                              ------------------------------ ชื่อการาจใน DATA [ห้ามตัวพิมพ์ใหญ่ / ห้ามเว้นวรรค / ห้ามตั้งชื่อยาว / ถ้าจะเว้นให้ใช้ _ แทน]
        labelname   = 'YELLOW GARAGE',                                          ------------------------------ ชื่อการาจที่แสดง
        location    = vector3(-336.6209, -977.8207, 31.080091),              ------------------------------ จุดเบิกรถ
        spawnlocation = vector3(-336.0669, -976.2336, 31.080091),            ------------------------------ จุด Spawn รถ
        spawnheading  = 342.47,                                              ------------------------------ ทิศทางหน้ารถ
        vehicletype   = 'car',
        deletelocation = vector3(-359.5485, -964.5596, 31.080097),           ------------------------------ จุดเก็บรถ
        Radius = 2.0,
        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 162.39,
            useConfigZ = true  -- 👈 ถ้าใส่อันนี้ก็ไม่ต้องหาพื้น ใช้ z ตาม config เลย
            ------------------------------ ทิศทาง Prop เบิกรถ
        },
        Propdelete = {
            model   = "un_bendix_prop_deposit_assist",
            heading = 145.76                                                  ------------------------------ ทิศทาง Prop เก็บรถ
        }
    },

    -- จุดเก็บรถมากกว่า 1 จุด ภายในการาจเดียวกัน
    -- {   
    --     deletelocation = vector3(1720.6622, 3775.0854, 34.369995),                                            ------------------------------ ทิศทางหน้ารถ
    --     vehicletype   = 'car',

    --     Propdelete = {
    --         model   = "un_bendix_prop_deposit_assist",
    --         heading = 216.97                                                  ------------------------------ ทิศทาง Prop เก็บรถ
    --     }
    -- },
    
    -- จุดเบิก ภายในการาจเดียวกัน
    {   
        location      = vector3(-333.1043, -979.0552, 31.080083),            ------------------------------ จุดเบิกรถ
        spawnlocation = vector3(-332.5077, -977.2586, 31.080083),            ------------------------------ จุด Spawn รถ
        spawnheading  = 341.54,                                              ------------------------------ ทิศทางหน้ารถ
        vehicletype   = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 164.19                                                  ------------------------------ ทิศทาง Prop เบิกรถ
        }
    },

    {   
        location      = vector3(-329.6533, -980.2556, 31.080083),            ------------------------------ จุดเบิกรถ
        spawnlocation = vector3(-329.0006, -978.6005, 31.080083),            ------------------------------ จุด Spawn รถ
        spawnheading  = 341.08,                                              ------------------------------ ทิศทางหน้ารถ
        vehicletype   = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 163.03                                                  ------------------------------ ทิศทาง Prop เบิกรถ
        }
    },

    {   
        location      = vector3(-326.1991, -981.5869, 31.080083),            ------------------------------ จุดเบิกรถ
        spawnlocation = vector3(-325.6171, -979.8433, 31.080083),            ------------------------------ จุด Spawn รถ
        spawnheading  = 342.56,                                              ------------------------------ ทิศทางหน้ารถ
        vehicletype   = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 163.93                                                  ------------------------------ ทิศทาง Prop เบิกรถ
        }
    },
-----------------------------------------------------------------------------------------------------------------------------------------------

}
