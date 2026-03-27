Config = Config or {}

-- =========================================================
-- Deposit Location Config
-- =========================================================
-- ฟิลด์หลักต่อรายการ:
--   Label / GhostZone / active
--   location / spawnlocation / spawnheading
--   deletelocation / distDelete / autodelete
--   Propspawn = { model, heading }

Config.DepositMarker1 = {
    type = 1,
    r = 200, g = 200, b = 30,
    x = 3.0, y = 3.0, z = 2.00,
}

Config.DepositMarker2 = {
    type = 28,
    r = 255, g = 255, b = 255,
    x = 10.7, y = 10.7, z = 10.7,
} -- วงใน

-- Config.DepositMarker3 = { type = 28, r = 0, g = 188, b = 255, x = 15.7, y = 15.7, z = 15.7 } -- วงนอก
-- Config.npc_id = "s_m_m_security_01"
-- Config.npc_anim = { dict = "amb@world_human_cop_idles@idle_b", name = "idle_d" }

Config.depositvehicle = {    
    -- {   
    --     Label = 'MINE',
    --     -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
    --     location       = vector3(-1767.603, 2859.6235, 32.806537),
    --     spawnlocation  = vector3(-1762.777, 2867.6213, 32.806533),
    --     -- npcheading     = 138.4,
    --     spawnheading   = 30.74,
    --     deletelocation = vector3(-1774.255, 2862.3815, 32.806537),
    --     distDelete     = 25.0,
    --     active = true,
    --     Propspawn = {
    --         model   = "dx_seacity_dropgarage",
    --         heading = 138.4
    --     },

    -- },
    {   
        Label = '[BLACKOUT] AIRPORT',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1165.8861, -2313.2949, 13.9814),   -- จุดเบิก
        spawnlocation  = vector3(-1155.864, -2357.927, 13.945137), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 239.15,                -- ทิศทางรถ
        deletelocation = vector3(-1191.3361, -2298.3340, 12.9616), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 238.27  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] VINEWOOD',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(670.5044, 628.2336, 129.1062),   -- จุดเบิก
        spawnlocation  = vector3(713.73199, 634.48553, 128.91137), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 245.96,                -- ทิศทางรถ
        deletelocation = vector3(641.2721, 626.8024, 128.0864), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 200.91  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] MINT LANDMARK',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-557.4048, 338.3140, 84.4068),   -- จุดเบิก
        spawnlocation  = vector3(-540.286, 352.46322, 83.042854), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 174.25,                -- ทิศทางรถ
        deletelocation = vector3(-622.1251, 339.3041, 84.3231), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 356.00  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] VINEWOOD PUMP',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(641.8809, 210.9737, 97.8024),   -- จุดเบิก
        spawnlocation  = vector3(673.70098, 233.60041, 94.139884), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 238.15,                -- ทิศทางรถ
        deletelocation = vector3(634.7095, 171.8123, 95.6103), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 164.95  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] ECONOMY',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1646.6067, -928.5041, 8.3331),   -- จุดเบิก
        spawnlocation  = vector3(-1616.362, -925.4939, 8.7108287), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 319.66,                -- ทิศทางรถ
        deletelocation = vector3(-1685.1974, -910.0555, 7.0538), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 141.04  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] LEFT HARBOR',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-410.4587, -2704.7112, 6.0002),   -- จุดเบิก
        spawnlocation  = vector3(-341.4349, -2691.946, 6.050199), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 321.21,                -- ทิศทางรถ
        deletelocation = vector3(-404.9213, -2726.7002, 5.0172), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 45.29 -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] REBEL CONNECT',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(379.0924, -2148.3579, 15.9145),   -- จุดเบิก
        spawnlocation  = vector3(428.89636, -2098.602, 20.704401), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 232.20,                -- ทิศทางรถ
        deletelocation = vector3(369.3448, -2126.3010, 15.2507), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 17.53  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] BUILDING CENTER',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(34.1320, -613.4838, 31.6286),   -- จุดเบิก
        spawnlocation  = vector3(53.473491, -641.8723, 31.63495), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 70.02,                -- ทิศทางรถ
        deletelocation = vector3(10.7348, -579.9958, 30.6457), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 160.31  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] HEART HOUSE',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1348.8988, -741.2853, 67.1665),   -- จุดเบิก
        spawnlocation  = vector3(1312.3009, -722.6347, 65.03984), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 63.29,                -- ทิศทางรถ
        deletelocation = vector3(1379.4882, -741.5297, 66.2499), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 166.57  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] RED LANDMARK',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1127.9069, -458.5598, 35.5753),   -- จุดเบิก
        spawnlocation  = vector3(-1077.556, -481.186, 36.596244), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 210.06,                -- ทิศทางรถ
        deletelocation = vector3(-1134.7544, -449.2495, 34.5674), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 205.00  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] BEIGE LANDMARK',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-630.0529, -197.7554, 37.7057),   -- จุดเบิก
        spawnlocation  = vector3(-668.3004, -185.5874, 37.679725), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 206.52,                -- ทิศทางรถ
        deletelocation = vector3(-597.1911, -192.1740, 36.7148), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 159.04  -- ทิศทางPROP การาจ
        },
        
    },
    -- {   
    --     Label = 'EVENT_BLACKOUT12',
    --     -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
    --     location       = vector3(66.6434, 8.6669, 68.9666),   -- จุดเบิก
    --     spawnlocation  = vector3(-4.18051, 4.1203937, 71.050537), -- จุดสปาวรถ
    --     -- npcheading     = 138.4,
    --     active = false,
    --     spawnheading   = 339.15,                -- ทิศทางรถ
    --     deletelocation = vector3(79.3128, 17.3285, 68.1185), -- จุดลบรถ
    --     distDelete     = 50.0,  -- ระยะในการลบ

    --     Propspawn = {
    --         model   = "dx_seacity_dropgarage",
    --         heading = 339.38  -- ทิศทางPROP การาจ
    --     },
        
    -- },
    {   
        Label = '[BLACKOUT] GOLD CLUB',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-813.4896, -106.5406, 37.5937),   -- จุดเบิก
        spawnlocation  = vector3(-792.1406, -98.97095, 37.662357), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 296.67,                -- ทิศทางรถ
        deletelocation = vector3(-839.0500, -119.4210, 36.6200), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 299.29  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[BLACKOUT] HOSPITAL',
        GhostZone = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(818.1556, -1334.1005, 26.1007),   -- จุดเบิก
        spawnlocation  = vector3(772.63964, -1330.229, 26.241014), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = false,
        spawnheading   = 270.38,                -- ทิศทางรถ
        deletelocation = vector3(835.9423, -1357.7258, 25.1137), -- จุดลบรถ
        distDelete     = 50.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 85.86  -- ทิศทางPROP การาจ
        },
        
    },

    {   
        Label = '[JOB] RED CUBE',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1418.8398, 1499.9564, 113.73063),   -- จุดเบิก
        spawnlocation  = vector3(1443.4715, 1527.1823, 111.64017), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 340.61,                -- ทิศทางรถ
        deletelocation = vector3(1423.5318, 1480.441, 112.84559), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 23.03  -- ทิศทางPROP การาจ
        },

    },
        {   
        Label = 'FISHING',
        -- autodelete = true, vector4(-219.1488, 6555.3466, 10.957326, 138.74763)
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-219.1488, 6555.3466, 10.957326),   -- จุดเบิก
        spawnlocation  = vector3(-201.8586, 6522.3979, 11.098021), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 120.0,                -- ทิศทางรถ
        deletelocation = vector3(-207.1758, 6558.5395, 11.074957), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 138.74763  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = '[JOB] DURIAN',
        autodelete = true, -- vector4(1131.9168, 1982.4514, 60.023384, 189.23124)
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม vector4(1135.2132, 1970.0625, 60.218723, 97.042572)
        location       = vector3(1131.9168, 1982.4514, 60.023384),   -- จุดเบิก
        spawnlocation  = vector3(1135.2132, 1970.0625, 60.218723), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 97.042572,                -- ทิศทางรถ
        deletelocation = vector3(1126.3216, 2004.7655, 58.884616), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 189.23124  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = '[JOB] CYAN CUBE',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-0.326685, 2904.9599, 57.032028),   -- จุดเบิก
        spawnlocation  = vector3(12.940658, 2899.3103, 57.506244), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 132.36021,                -- ทิศทางรถ
        deletelocation = vector3(-13.2218, 2919.7065, 56.793888), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 216.82717  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[JOB] ORANGE CUBE',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1835.908, 2522.0144, 3.2689254),   -- จุดเบิก
        spawnlocation  = vector3(-1846.667, 2515.2167, 1.9320573), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 75.512886,                -- ทิศทางรถ
        deletelocation = vector3(-1815.849, 2514.8134, 2.0566325), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 63.816596  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[JOB] BLUE CUBE',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-2583.507, 2445.0776, 2.8536462),   -- จุดเบิก
        spawnlocation  = vector3(-2619.281, 2454.2336, 1.2320997), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 157.09,                -- ทิศทางรถ
        deletelocation = vector3(-2589.613, 2429.8862, 1.3018348), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 349.03  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = 'ANIMAL',
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(2900.9514, -728.0211, 11.747536),   -- จุดเบิก
        spawnlocation  = vector3(2897.2792, -728.1505, 11.747521), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 1.38,                -- ทิศทางรถ
        deletelocation = vector3(2883.2319, -711.2363, 11.747536), -- จุดลบรถ
        distDelete     = 32.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 182.63  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = '[PROCESS] CUBE',
        -- autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1733.7794, -1122.5393, 12.0186),   -- จุดเบิก
        spawnlocation  = vector3(-1708.099, -1083.295, 13.107012), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 319.85,                -- ทิศทางรถ
        deletelocation = vector3(-1714.623, -1119.916, 13.146302), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 136.53  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = 'ECONOMY',
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-3026.192, 95.07833, 11.606292),   -- จุดเบิก
        spawnlocation  = vector3(-3026.192, 95.07833, 11.606292), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 320.68,                -- ทิศทางรถ
        deletelocation = vector3(-3015.822, 87.198608, 11.609162), -- จุดลบรถ
        distDelete     = 20.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 141.9185  -- ทิศทางPROP การาจ
        },

    },
    {   
        Label = '[PROCESS] IRON & COPPER ',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1228.5337, -2186.8093, 41.0314),   -- จุดเบิก
        spawnlocation  = vector3(1233.9504, -2214.213, 41.404624), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 183.03,                -- ทิศทางรถ
        deletelocation = vector3(1220.4093, -2190.175, 41.690425), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 296.94  -- ทิศทางPROP การาจ
        },
 
    },
    {   
        Label = '[PROCESS] GOLD & DIAMOND',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1241.3248, -2440.9180, 43.7499),   -- จุดเบิก
        spawnlocation  = vector3(1235.7188, -2397.094, 47.50954), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 352.53,                -- ทิศทางรถ
        deletelocation = vector3(1227.4937, -2440.515, 44.481582), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 233.14  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[JOB] MINE',
        autodelete = true,
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(2969.1416, 2795.2453, 40.740386),   -- จุดเบิก
        spawnlocation  = vector3(2977.6955, 2813.6701, 44.005619), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 31.49,                -- ทิศทางรถ
        deletelocation = vector3(2944.50, 2795.37, 40.60), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 276.01  -- ทิศทางPROP การาจ
        },

    },

    {   
        Label = '[ROBSTORE] HEART HOUSE', -- ร้านปั้มหอย
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1168.3936, -324.2094, 68.2929),   -- จุดเบิก
        spawnlocation  = vector3(1168.535, -354.3684, 67.668365), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 167.02,                -- ทิศทางรถ
        deletelocation = vector3(1164.7119, -322.8236, 69.205001), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 99.89  -- ทิศทางPROP การาจ
        },
        
    },
    {   
        Label = '[ROBSTORE] RIGHT PUMP', -- ร้านอาเทน่า
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(2561.9379, 396.52545, 108.62023),   -- จุดเบิก
        spawnlocation  = vector3(2595.7702, 390.44879, 108.37175), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 269.66,                -- ทิศทางรถ
        deletelocation = vector3(2554.86181640625, 381.4385986328125, 108.52752685546876), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 89.28  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] LEFT BANK', -- ร้านริมทะเลฝั่งตะขอแดง
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-2971.6821, 398.4995, 14.0790),   -- จุดเบิก
        spawnlocation  = vector3(-2973.205, 424.36575, 15.110995), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 85.43,                -- ทิศทางรถ
        deletelocation = vector3(-2967.0400390625, 390.9700012207031, 15.03999996185302), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 176.49  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] RED STORE', -- ร้านศาลาแดง
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1230.1942, -902.9892, 11.1675),   -- จุดเบิก
        spawnlocation  = vector3(-1247.184, -871.2023, 12.428602), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 213.29,                -- ทิศทางรถ
        deletelocation = vector3(-1222.4202880859375, -907.7393188476564, 12.33136081695556), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 212.88  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] VINEWOOD PUMP', -- ร้านบนแลนเขียว
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(381.8288, 320.4831, 102.3247),   -- จุดเบิก
        spawnlocation  = vector3(365.30316, 328.28924, 103.63064), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 165.61,                -- ทิศทางรถ
        deletelocation = vector3(373.1116943359375, 326.35205078125, 103.67135620117188), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 347.89 -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] WHITE LANDMARK', -- ร้านหมุนหอย
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1142.8910, -978.8947, 45.2951),   -- จุดเบิก
        spawnlocation  = vector3(1152.227, -993.1605, 45.553115), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 4.25,                -- ทิศทางรถ
        deletelocation = vector3(1134.5557861328125, -982.4132080078124, 46.420814514160151), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 98.44  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] STADIUM', -- ร้านปั้มพาวรถ
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-58.4628, -1746.6619, 28.3300),   -- จุดเบิก
        spawnlocation  = vector3(-42.53868, -1742.089, 29.131946), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 49.80,                -- ทิศทางรถ
        deletelocation = vector3(-47.2449836730957, -1757.4671630859375, 29.55429649353027), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 226.47  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] LEFT LAP', -- ร้านปั้มDGG
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1816.7905, 789.4924, 136.9344),   -- จุดเบิก
        spawnlocation  = vector3(-1808.975, 780.89636, 137.26982), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 218.81,                -- ทิศทางรถ
        deletelocation = vector3(-1820.559326171875, 793.763916015625, 138.19839477539065), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 43.61  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] BUILDING CENTER', -- ร้านกลางตึกปูนใหญ่
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-698.3033, -921.5776, 18.0139),   -- จุดเบิก
        spawnlocation  = vector3(-695.785, -981.1608, 20.390144), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 1.20,                -- ทิศทางรถ
        deletelocation = vector3(-706.7357788085938, -913.4804077148438, 19.43159484863281), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 268.83  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] OLD HOSPITAL', -- ร้านกลางเมืองโรงบาล
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(33.4768, -1350.8281, 28.3329),   -- จุดเบิก
        spawnlocation  = vector3(52.667015, -1358.388, 29.289169), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 271.92,                -- ทิศทางรถ
        deletelocation = vector3(24.497858, -1344.98, 29.497011), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 359.60  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = '[ROBSTORE] GRAVE LANDMARK', -- ร้านหลุมศพ
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(-1496.7092, -381.1508, 39.4375),   -- จุดเบิก
        spawnlocation  = vector3(-1481.86, -406.0501, 37.432193), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 227.33,                -- ทิศทางรถ
        deletelocation = vector3(-1486.276, -378.0216, 40.163448), -- จุดลบรถ
        distDelete     = 25.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 318.05  -- ทิศทางPROP การาจ
        },
    },

    {   
        Label = 'SOUTH REBEL VAULT', -- ร้านหลุมศพ
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1193.06641, -2936.06665, 5.902101),   -- จุดเบิก
        spawnlocation  = vector3(1188.8409, -2919.769, 5.9021015), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 87.53,                -- ทิศทางรถ
        deletelocation = vector3(1193.1563, -2938.646, 5.902112), -- จุดลบรถ
        distDelete     = 17.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 270.46  -- ทิศทางPROP การาจ
        },
    },
    {   
        Label = 'SANDY REBEL VAULT', -- ร้านหลุมศพ
        -- isNotdraw = true,  -- ✅ ถ้าใส่ จะไม่สร้าง marker วงกลม
        location       = vector3(1509.98059, 3921.00586, 37.2385711),   -- จุดเบิก
        spawnlocation  = vector3(1515.3265, 3879.7019, 37.282558), -- จุดสปาวรถ
        -- npcheading     = 138.4,
        active = true,
        spawnheading   = 216.15,                -- ทิศทางรถ
        deletelocation = vector3(1512.0183, 3922.5563, 37.238521), -- จุดลบรถ
        distDelete     = 17.0,  -- ระยะในการลบ
        rangToRemove   = 10, 

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 43.8  -- ทิศทางPROP การาจ
        },
    },
    
    {   -- จุด 1
        Label         = '[PIPE] 1',
        GhostZone     = true,
        location      = vector3(1017.8423, -2515.533, 28.302299),   -- จุดเบิก
        spawnlocation = vector3(980.91772, -2448.622, 28.540159),   -- จุดสปาวรถ
        active        = false,
        spawnheading  = 175.53369,                                     -- ทิศทางรถ
        deletelocation= vector3(988.81298, -2523.901, 28.302011),   -- จุดลบรถ
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 267.8208,                                       -- ทิศทาง PROP การาจ
        },
    },

    {   -- จุด 2
        Label         = '[PIPE] 2',
        GhostZone     = true,
        location      = vector3(-117.7162, -2005.284, 18.01695),
        spawnlocation = vector3(-137.5039, -1988.26, 22.805313),
        active        = false,
        spawnheading  = 90.500961,
        deletelocation= vector3(-83.01059, -2016.247, 18.030927),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 86.117095,
        },
    },

    {   -- จุด 3
        Label         = '[PIPE] 3',
        GhostZone     = true,
        location      = vector3(508.1921, -2174.387, 5.9516463),
        spawnlocation = vector3(509.3417, -2259.908, 5.9802846),
        active        = false,
        spawnheading  = 239.18124,
        deletelocation= vector3(514.72314, -2143.479, 5.9634065),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 83.621452,
        },
    },

    {   -- จุด 4
        Label         = '[PIPE] 4',
        GhostZone     = true,
        location      = vector3(-762.6509, -1428.437, 5.0005173),
        spawnlocation = vector3(-710.5235, -1389.62, 5.0005178),
        active        = false,
        spawnheading  = 316.48129,
        deletelocation= vector3(-735.9303, -1457.427, 5.0005269),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 52.912002,
        },
    },

    {   -- จุด 5
        Label         = '[PIPE] 5',
        GhostZone     = true,
        location      = vector3(-1577.325, -1064.297, 6.4374675),
        spawnlocation = vector3(-1457.288, -1084.379, 3.4577057),
        active        = false,
        spawnheading  = 230.37837,
        deletelocation= vector3(-1569.869, -1103.901, 4.2366714),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 54.481445,
        },
    },

    {   -- จุด 6
        Label         = '[PIPE] 6',
        GhostZone     = true,
        location      = vector3(-1362.514, 142.57858, 56.390163),
        spawnlocation = vector3(-1405.422, 87.673622, 53.149414),
        active        = false,
        spawnheading  = 239.40132,
        deletelocation= vector3(-1352.609, 135.95405, 56.264026),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 186.94488,
        },
    },

    {   -- จุด 7
        Label         = '[PIPE] 7',
        GhostZone     = true,
        location      = vector3(-265.3144, 310.59405, 93.254486),
        spawnlocation = vector3(-190.8523, 287.28436, 92.987937),
        active        = false,
        spawnheading  = 179.78602,
        deletelocation= vector3(-279.7006, 318.36819, 93.254646),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 169.27308,
        },
    },

    {   -- จุด 8
        Label         = '[PIPE] 8',
        GhostZone     = true,
        location      = vector3(986.29797, -3180.145, 5.9007964),
        spawnlocation = vector3(945.33178, -3133.246, 5.8963871),
        active        = false,
        spawnheading  = 0.0113046,
        deletelocation= vector3(1023.475, -3199.028, 5.9015674),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 349.76629,
        },
    },

    {   -- จุด 9
        Label         = '[PIPE] 9',
        GhostZone     = true,
        location      = vector3(277.78561, -2780.747, 6.0206699),
        spawnlocation = vector3(280.25436, -2732.349, 6.0201592),
        active        = false,
        spawnheading  = 60.115947,
        deletelocation= vector3(262.19827, -2835.803, 6.0006499),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 265.58197,
        },
    },

    {   -- จุด 10
        Label         = '[PIPE] 10',
        GhostZone     = true,
        location      = vector3(325.57919, -2017.021, 21.397474),
        spawnlocation = vector3(277.85156, -2008.356, 19.747501),
        active        = false,
        spawnheading  = 229.44812,
        deletelocation= vector3(345.50292, -2049.298, 21.584602),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 318.59167,
        },
    },

    {   -- จุด 11
        Label         = '[PIPE] 11',
        GhostZone     = true,
        location      = vector3(118.64116, -589.9771, 43.830448),
        spawnlocation = vector3(240.82003, -564.7902, 43.27872),
        active        = false,
        spawnheading  = 248.52691,
        deletelocation= vector3(153.46656, -567.6218, 43.896572),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 250.44732,
        },
    },

    {   -- จุด 12
        Label         = '[PIPE] 12',
        GhostZone     = true,
        location      = vector3(952.51531, -584.8614, 58.334278),
        spawnlocation = vector3(1007.7805, -524.6152, 60.468219),
        active        = false,
        spawnheading  = 206.74617,
        deletelocation= vector3(937.6126, -553.2335, 59.401283),
        distDelete    = 40.0,

        Propspawn = {
            model   = "dx_seacity_dropgarage",
            heading = 204.82394,
        },
    },
}




-- Config.depositvehiclePoly = {
    
--     -- อีโค
--     {   
--         Label = 'เหมือง',
--         location = vector3(-365.3299865722656 , 264.6700134277344 , 84.83999633789062),
--         spawnlocation = vector3(-357.9599914550781 , 268.1099853515625 , 84.83000183105469),
--         npcheading = 90.7,
--         spawnheading = 179.1,
--         deletelocation = vector3(-364.8399963378906 , 257.7200012207031 , 50.37000274658203),
--         distDelete = 0.0,
--     },
-- }

-- CheckLoopTime = 1000

-- AllZones = {	
-- 	["อีโค"] = {
-- 		Debug = false,        
-- 		Zones = {
-- 			{
-- 				minZ = 75.919,
-- 				maxZ = 88.5,
-- 				Coords = {
-- 				  vector2(-353.04998779296875 , 261.0299987792969), 
-- 				  vector2(-353.79998779296875 , 286.25 ),
-- 				  vector2(-385.9700012207031 , 273.9299926757813 ),
-- 				  vector2(-385.19000244140625 , 257.4700012207031),
				
-- 				},
-- 			},
-- 		},
-- 	}
	
	
-- }




