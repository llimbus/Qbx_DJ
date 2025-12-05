fx_version 'cerulean'
game 'gta5'

author 'llimbus'
description 'Immersive DJ Job Script'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- ============================================
-- ORDEM DE CARREGAMENTO (IMPORTANTE!)
-- ============================================
-- 1. Config
-- 2. Core modules (shared, utils, state)
-- 3. Functional modules (audio, beat, zones, etc)
-- 4. Effects modules
-- 5. Target modules
-- 6. Client main (legado - será migrado)
-- ============================================

shared_script 'config.lua'

client_scripts {
    -- CORE MODULES (carregados primeiro)
    'core/core_shared.lua',      -- Variáveis globais e constantes
    'core/core_utils.lua',       -- Funções utilitárias
    'core/core_state.lua',       -- Gerenciamento de estado (✅ Implementado)
    
    -- FUNCTIONAL MODULES (a implementar)
    -- 'modules/module_audio.lua',
    -- 'modules/module_beat.lua',
    -- 'modules/module_zones.lua',
    -- 'modules/module_props.lua',
    -- 'modules/module_placement.lua',
    -- 'modules/module_playlist.lua',
    -- 'modules/module_ui.lua',
    
    -- EFFECTS MODULES
    'effects_core.lua',          -- Core de efeitos
    'effects_lights.lua',        -- Stage Lights
    'effects_lasers.lua',        -- Lasers
    -- 'effects/effects_smoke.lua',     -- Fumaça (a implementar)
    -- 'effects/effects_particles.lua', -- Confetti, Bubbles (a implementar)
    -- 'effects/effects_pyro.lua',      -- Pyro, CO2, UV (a implementar)
    
    -- TARGET MODULES (a implementar)
    -- 'target/target_core.lua',
    -- 'target/target_ox.lua',
    -- 'target/target_qb.lua',
    -- 'target/target_fallback.lua',
    
    -- CLIENT MAIN (legado - será migrado gradualmente)
    'client.lua'
}

server_script 'server.lua'
