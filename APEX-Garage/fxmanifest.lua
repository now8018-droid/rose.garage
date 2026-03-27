fx_version 'cerulean'

game 'gta5'

description 'APEX-Garage'

version '1.0.0'
lua54 'yes'

files {
	'web/index.html',
	'web/styles.css',
	'web/script.js',
	'web/img/*.png'
}

ui_page {
	'web/index.html'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config/core/main.lua',
	-- 'config/core/main.lua',
	'config/locations/pound.lua',
	'config/locations/garage.lua',
	'config/locations/deposit.lua',
	'config/ui/vehicle_image.lua',
	'config/core/webhook.lua',
	'server/modules/ui.lua',
	'server/server.lua'
}

client_scripts {
	'@es_extended/locale.lua',	
	'config/core/main.lua',	
	'config/locations/pound.lua',
	'config/locations/garage.lua',
	'config/locations/deposit.lua',
	'config/ui/vehicle_image.lua',
	'client/client.lua',
	'client/add.lua',
}

dependencies {
	'es_extended',
	-- 'esx_vehicleshop'
}
