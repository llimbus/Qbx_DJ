-- ============================================
-- QBXDJ - CORE DO SISTEMA DE EFEITOS
-- ============================================
-- Este arquivo DEVE ser carregado PRIMEIRO
-- Contém variáveis globais e funções auxiliares
-- ============================================

print("[DJ Effects Core] Loading core module...")

-- ============================================
-- VARIÁVEIS GLOBAIS (compartilhadas entre módulos)
-- ============================================

-- Estado da música e batidas
if not DJMusicBeat then
    DJMusicBeat = {
        bpm = 128,
        beat = 0,
        intensity = 0.5,
        lastBeatTime = 0,
        isPlaying = false
    }
end

-- Efeitos ativos por entidade
if not DJActiveEffects then
    DJActiveEffects = {}
end

-- Zonas de áudio
if not DJAudioZones then
    DJAudioZones = {}
end

-- ============================================
-- FUNÇÕES AUXILIARES (usadas por todos os efeitos)
-- ============================================

-- Converter HEX para RGB
function DJHexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

-- Converter HSV para RGB
function DJHSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h / 60)
    local f = (h / 60) - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- Verificar se está no beat
function DJIsOnBeat()
    if not DJMusicBeat then return false end
    local timeSinceBeat = GetGameTimer() - DJMusicBeat.lastBeatTime
    local beatInterval = (60000 / DJMusicBeat.bpm)
    local beatWindow = beatInterval * 0.15
    return timeSinceBeat < beatWindow
end

-- Obter fase do beat (0.0 a 1.0)
function DJGetBeatPhase()
    if not DJMusicBeat or not DJMusicBeat.isPlaying then return 0 end
    local timeSinceBeat = GetGameTimer() - DJMusicBeat.lastBeatTime
    local beatInterval = (60000 / DJMusicBeat.bpm)
    return math.min(timeSinceBeat / beatInterval, 1.0)
end

-- Verificar se música está tocando na zona
function DJIsMusicPlayingInZone(entity)
    if not DJMusicBeat then return false end
    return DJMusicBeat.isPlaying
end

-- Atualizar estado da música (chamado pelo client.lua)
function DJUpdateMusicBeat(bpm, beat, isPlaying)
    DJMusicBeat.bpm = bpm or 128
    DJMusicBeat.beat = beat or 0
    DJMusicBeat.lastBeatTime = GetGameTimer()
    DJMusicBeat.isPlaying = isPlaying or false
end

-- Inicializar efeito para uma entidade
function DJInitEffect(entity, effectId, config)
    if not DJActiveEffects[entity] then
        DJActiveEffects[entity] = { effects = {} }
    end
    DJActiveEffects[entity].effects[effectId] = { config = config }
end

-- Remover efeito de uma entidade
function DJRemoveEffect(entity, effectId)
    if DJActiveEffects[entity] and DJActiveEffects[entity].effects[effectId] then
        DJActiveEffects[entity].effects[effectId] = nil
        print(string.format("[DJ Effects Core] Effect %s removed from entity %d", effectId, entity))
    end
end

-- Verificar se efeito está ativo
function DJIsEffectActive(entity, effectId)
    return DJActiveEffects[entity] and DJActiveEffects[entity].effects[effectId] ~= nil
end

-- Parar todos os efeitos de uma entidade
function DJStopAllEffects(entity)
    if DJActiveEffects[entity] then
        print(string.format("[DJ Effects Core] Stopping all effects for entity %d", entity))
        DJActiveEffects[entity] = nil
    end
end

-- ============================================
-- DISPATCHER DE EFEITOS
-- ============================================

function DJStartConfiguredEffect(entity, effectId, config)
    print("[DJ Effects Core] Starting configured effect")
    print("[DJ Effects Core] Effect ID:", effectId)
    print("[DJ Effects Core] Config type:", config.type)
    
    -- Inicializar efeito
    DJInitEffect(entity, effectId, config)
    
    -- Chamar função específica do efeito
    if config.type == 'lights' then
        print("[DJ Effects Core] Dispatching to STAGE LIGHTS")
        DJStartStageLightsEffect(entity, effectId, config.lights or {})
        
    elseif config.type == 'lasers' then
        print("[DJ Effects Core] Dispatching to LASER SHOW")
        DJStartLaserShowEffect(entity, effectId, config.lasers or {})
        
    elseif config.type == 'smoke' then
        print("[DJ Effects Core] Dispatching to SMOKE MACHINE")
        DJStartSmokeEffect(entity, effectId, config.smoke or {})
        
    elseif config.type == 'confetti' then
        print("[DJ Effects Core] Dispatching to CONFETTI")
        DJStartConfettiEffect(entity, effectId, config.confetti or {})
        
    elseif config.type == 'bubbles' then
        print("[DJ Effects Core] Dispatching to BUBBLES")
        DJStartBubblesEffect(entity, effectId, config.bubbles or {})
        
    elseif config.type == 'pyro' then
        print("[DJ Effects Core] Dispatching to PYROTECHNICS")
        DJStartPyroEffect(entity, effectId, config.pyro or {})
        
    elseif config.type == 'co2' then
        print("[DJ Effects Core] Dispatching to CO2 JETS")
        DJStartCO2Effect(entity, effectId, config.co2 or {})
        
    elseif config.type == 'uv' then
        print("[DJ Effects Core] Dispatching to UV LIGHTS")
        DJStartUVEffect(entity, effectId, config.uv or {})
        
    elseif config.type == 'firework' then
        print("[DJ Effects Core] Dispatching to FIREWORKS")
        DJStartFireworkEffect(entity, effectId, config.firework or {})
        
    else
        print("[DJ Effects Core] ⚠️ Unknown effect type:", config.type)
    end
end

print("[DJ Effects Core] ✓ Core module loaded successfully")
