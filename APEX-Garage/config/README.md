# APEX-Garage config structure

- `core/`
  - `main.lua`: global tuning, marker defaults, dimensions, misc behavior.
  - `webhook.lua`: webhook endpoints.
- `locations/`
  - `garage.lua`: garage interaction locations.
  - `pound.lua`: pound interaction locations.
  - `deposit.lua`: deposit interaction locations.
- `ui/`
  - `vehicle_image.lua`: vehicle image/name mapping for NUI.

> Keep load order: `core/main.lua` must be loaded before other config files.
