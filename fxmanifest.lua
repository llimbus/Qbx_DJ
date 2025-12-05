fx_version 'cerulean'
game 'gta5'

author 'llimbus'
description 'Immersive DJ Job Script'
version '0.1.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Arquivos de efeitos visuais (carregados primeiro)
client_scripts {
    'effects_core.lua',      -- CORE: Variáveis globais e funções auxiliares (PRIMEIRO!)
    'effects_lights.lua',    -- Stage Lights
    'effects_lasers.lua',    -- Lasers
    'client.lua'             -- Código principal (ÚLTIMO!)
}

server_script 'server.lua'
