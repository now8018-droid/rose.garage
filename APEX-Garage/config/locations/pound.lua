Config = Config or {}

-- =========================================================
-- Pound Location Config
-- =========================================================
-- ฟิลด์หลักต่อรายการ:
--   location / spawnlocation / spawnheading
--   vehicletype = 'car' | 'bike' | 'helicopter'
--   Radius / job
--   Propspawn = { model, heading }

Config.PoundMarker = {
    type = 36,
    r = 255, g = 165, b = 0, a = 100,
    x = 1.5, y = 1.5, z = 1.2,
}

Config.poundDetail = {

    {   
        location = vector3(-308.5839, -988.0506, 31.0806),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(-311.7836, -985.6757, 30.0618),         ------------------------------ จุด Spawn รถ
        spawnheading = 342.47,                                            ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "dx_seacity_droppound",
            heading = 162.39                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },
}
