-- APEX-Garage required SQL
-- Run this once on your ESX database.

-- 1) Extra columns required by APEX-Garage on owned_vehicles
ALTER TABLE `owned_vehicles`
    ADD COLUMN IF NOT EXISTS `vehiclename` VARCHAR(64) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `health_vehicles` LONGTEXT NULL,
    ADD COLUMN IF NOT EXISTS `deposit` INT NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `police` TINYINT(1) NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `job` VARCHAR(64) NULL DEFAULT NULL;

-- 2) Indexes used by server queries
CREATE INDEX IF NOT EXISTS `idx_owned_vehicles_owner` ON `owned_vehicles` (`owner`);
CREATE INDEX IF NOT EXISTS `idx_owned_vehicles_plate` ON `owned_vehicles` (`plate`);
CREATE INDEX IF NOT EXISTS `idx_owned_vehicles_deposit` ON `owned_vehicles` (`deposit`);

-- 3) Custom props table used by setStateVehicle flow
CREATE TABLE IF NOT EXISTS `apex_custom_props` (
    `plate` VARCHAR(32) NOT NULL,
    `props` LONGTEXT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
