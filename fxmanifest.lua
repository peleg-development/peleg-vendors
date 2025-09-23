fx_version 'cerulean'
game 'gta5'

author 'Peleg'
description 'Vendor System with limit system'
version '1.0.0'

shared_scripts {
    "@ox_lib/init.lua",
    'configs/config.lua',
    'bridge/auto_detect.lua',
    'bridge/bridge.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**/*'
}

lua54 'yes'
