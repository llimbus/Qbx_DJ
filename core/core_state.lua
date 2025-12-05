-- ============================================
-- QBXDJ - CORE STATE MODULE
-- ============================================
-- Gerenciamento centralizado de estado global
-- Requer: core_shared.lua, core_utils.lua
-- ============================================
-- Data de Criação: 05/12/2025
-- Versão: 2.0.0
-- Autor: llimbus
-- ============================================
-- CHANGELOG:
-- 05/12/2025 - Criação inicial do módulo
-- ============================================

print("[DJ State] Loading state management module...")

-- ============================================
-- NAMESPACE
-- ============================================

DJState = {}

-- ============================================
-- CALLBACKS DE ESTADO
-- ============================================

-- Callbacks registrados para mudanças de estado
local stateCallbacks = {
    musicBeat = {},      -- Quando beat muda
    musicState = {},     -- Quando música toca/para
    effect = {},         -- Quando efeito é adicionado/removido
    zone = {},           -- Quando zona é criada/modificada
    prop = {},           -- Quando prop é spawnado/removido
    ui = {},             -- Quando UI abre/fecha
    playlist = {}        -- Quando playlist muda
}

-- Registrar callback para mudança de estado
-- @param type string - Tipo de callback ('musicBeat', 'effect', etc)
-- @param callback function - Função a ser chamada
-- @return number - ID do callback (para remover depois)
function DJState.RegisterCallback(type, callback)
    if not stateCallbacks[type] then
        DJUtils.Warn("Invalid callback type: %s", type)
        return nil
    end
    
    table.insert(stateCallbacks[type], callback)
    local id = #stateCallbacks[type]
    
    DJUtils.Debug("Callback registered: %s (ID: %d)", type, id)
    return id
end

-- Remover callback
-- @param type string - Tipo de callback
-- @param id number - ID do callback
function DJState.UnregisterCallback(type, id)
    if stateCallbacks[type] and stateCallbacks[type][id] then
        stateCallbacks[type][id] = nil
        DJUtils.Debug("Callback unregistered: %s (ID: %d)", type, id)
    end
end

-- Disparar callbacks
-- @param type string - Tipo de callback
-- @param ... any - Argumentos para o callback
local function triggerCallbacks(type, ...)
    if stateCallbacks[type] then
        for _, callback in pairs(stateCallbacks[type]) do
            if type(callback) == 'function' then
                local success, err = pcall(callback, ...)
                if not success then
                    DJUtils.Error("Callback error (%s): %s", type, err)
                end
            end
        end
    end
end

-- ============================================
-- MUSIC BEAT STATE
-- ============================================

-- Atualizar estado do beat
-- @param bpm number - BPM (60-180)
-- @param beat number - Beat atual (0-3)
-- @param isPlaying boolean - Se está tocando
function DJState.SetMusicBeat(bpm, beat, isPlaying)
    -- Validar BPM
    if bpm then
        bpm = DJUtils.Clamp(bpm, DJSystem.Constants.MIN_BPM, DJSystem.Constants.MAX_BPM)
        DJSystem.MusicBeat.bpm = bpm
    end
    
    -- Validar beat
    if beat then
        beat = math.floor(beat) % 4
        DJSystem.MusicBeat.beat = beat
    end
    
    -- Atualizar estado
    if isPlaying ~= nil then
        DJSystem.MusicBeat.isPlaying = isPlaying
    end
    
    -- Atualizar timestamp
    DJSystem.MusicBeat.lastBeatTime = GetGameTimer()
    
    -- Disparar callbacks
    triggerCallbacks('musicBeat', DJSystem.MusicBeat.bpm, DJSystem.MusicBeat.beat)
    
    DJUtils.Debug("Music beat updated: BPM=%d, Beat=%d, Playing=%s", 
        DJSystem.MusicBeat.bpm, DJSystem.MusicBeat.beat, tostring(DJSystem.MusicBeat.isPlaying))
end

-- Obter estado do beat
-- @return table - Estado completo do beat
function DJState.GetMusicBeat()
    return DJUtils.DeepCopy(DJSystem.MusicBeat)
end

-- Verificar se está no beat
-- @return boolean - Se está no beat
function DJState.IsOnBeat()
    if not DJSystem.MusicBeat.isPlaying then
        return false
    end
    
    local timeSinceBeat = GetGameTimer() - DJSystem.MusicBeat.lastBeatTime
    local beatInterval = (60000 / DJSystem.MusicBeat.bpm)
    local beatWindow = beatInterval * 0.15 -- 15% do intervalo
    
    return timeSinceBeat < beatWindow
end

-- Obter fase do beat (0.0 a 1.0)
-- @return number - Fase do beat
function DJState.GetBeatPhase()
    if not DJSystem.MusicBeat.isPlaying then
        return 0
    end
    
    local timeSinceBeat = GetGameTimer() - DJSystem.MusicBeat.lastBeatTime
    local beatInterval = (60000 / DJSystem.MusicBeat.bpm)
    
    return math.min(timeSinceBeat / beatInterval, 1.0)
end

-- Atualizar estado da música (play/pause/stop)
-- @param isPlaying boolean - Se está tocando
-- @param bpm number - BPM (opcional)
function DJState.SetMusicState(isPlaying, bpm)
    local oldState = DJSystem.MusicBeat.isPlaying
    
    DJSystem.MusicBeat.isPlaying = isPlaying
    if bpm then
        DJSystem.MusicBeat.bpm = DJUtils.Clamp(bpm, DJSystem.Constants.MIN_BPM, DJSystem.Constants.MAX_BPM)
    end
    
    -- Disparar callback se mudou
    if oldState ~= isPlaying then
        triggerCallbacks('musicState', isPlaying, DJSystem.MusicBeat.bpm)
        DJUtils.Info("Music state changed: %s", isPlaying and "Playing" or "Stopped")
    end
end

-- ============================================
-- EFFECTS STATE
-- ============================================

-- Adicionar efeito
-- @param entity number - Entidade
-- @param effectId string - ID do efeito
-- @param config table - Configuração do efeito
function DJState.AddEffect(entity, effectId, config)
    -- Inicializar se necessário
    if not DJSystem.ActiveEffects[entity] then
        DJSystem.ActiveEffects[entity] = { effects = {} }
    end
    
    -- Verificar limite
    local effectCount = DJUtils.TableCount(DJSystem.ActiveEffects[entity].effects)
    if effectCount >= DJSystem.Constants.MAX_EFFECTS_PER_PROP then
        DJUtils.Warn("Maximum effects per prop reached (%d)", DJSystem.Constants.MAX_EFFECTS_PER_PROP)
        return false
    end
    
    -- Adicionar efeito
    DJSystem.ActiveEffects[entity].effects[effectId] = {
        config = config,
        addedAt = GetGameTimer()
    }
    
    -- Disparar callback
    triggerCallbacks('effect', 'added', entity, effectId, config)
    
    DJUtils.Info("Effect added: Entity=%d, ID=%s, Type=%s", entity, effectId, config.type)
    return true
end

-- Remover efeito
-- @param entity number - Entidade
-- @param effectId string - ID do efeito
function DJState.RemoveEffect(entity, effectId)
    if DJSystem.ActiveEffects[entity] and DJSystem.ActiveEffects[entity].effects[effectId] then
        local config = DJSystem.ActiveEffects[entity].effects[effectId].config
        DJSystem.ActiveEffects[entity].effects[effectId] = nil
        
        -- Remover entidade se não tem mais efeitos
        if DJUtils.IsTableEmpty(DJSystem.ActiveEffects[entity].effects) then
            DJSystem.ActiveEffects[entity] = nil
        end
        
        -- Disparar callback
        triggerCallbacks('effect', 'removed', entity, effectId, config)
        
        DJUtils.Info("Effect removed: Entity=%d, ID=%s", entity, effectId)
        return true
    end
    
    return false
end

-- Atualizar configuração de efeito
-- @param entity number - Entidade
-- @param effectId string - ID do efeito
-- @param config table - Nova configuração
function DJState.UpdateEffect(entity, effectId, config)
    if DJSystem.ActiveEffects[entity] and DJSystem.ActiveEffects[entity].effects[effectId] then
        DJSystem.ActiveEffects[entity].effects[effectId].config = config
        
        -- Disparar callback
        triggerCallbacks('effect', 'updated', entity, effectId, config)
        
        DJUtils.Info("Effect updated: Entity=%d, ID=%s", entity, effectId)
        return true
    end
    
    return false
end

-- Verificar se efeito está ativo
-- @param entity number - Entidade
-- @param effectId string - ID do efeito
-- @return boolean - Se está ativo
function DJState.IsEffectActive(entity, effectId)
    return DJSystem.ActiveEffects[entity] and 
           DJSystem.ActiveEffects[entity].effects[effectId] ~= nil
end

-- Obter todos os efeitos de uma entidade
-- @param entity number - Entidade
-- @return table - Lista de efeitos
function DJState.GetEffects(entity)
    if DJSystem.ActiveEffects[entity] then
        return DJUtils.DeepCopy(DJSystem.ActiveEffects[entity].effects)
    end
    return {}
end

-- Parar todos os efeitos de uma entidade
-- @param entity number - Entidade
function DJState.StopAllEffects(entity)
    if DJSystem.ActiveEffects[entity] then
        local effects = DJSystem.ActiveEffects[entity].effects
        for effectId, _ in pairs(effects) do
            DJState.RemoveEffect(entity, effectId)
        end
        DJUtils.Info("All effects stopped for entity: %d", entity)
    end
end

-- ============================================
-- ZONES STATE
-- ============================================

-- Criar zona
-- @param zoneId string - ID da zona
-- @param djTable number - Entidade da mesa DJ
function DJState.CreateZone(zoneId, djTable)
    if not DJSystem.AudioZones[zoneId] then
        DJSystem.AudioZones[zoneId] = {
            djTable = djTable,
            speakers = {},
            effects = {},
            createdAt = GetGameTimer()
        }
        
        triggerCallbacks('zone', 'created', zoneId, djTable)
        DJUtils.Info("Zone created: %s (DJ Table: %d)", zoneId, djTable)
        return true
    end
    
    DJUtils.Warn("Zone already exists: %s", zoneId)
    return false
end

-- Deletar zona
-- @param zoneId string - ID da zona
function DJState.DeleteZone(zoneId)
    if DJSystem.AudioZones[zoneId] then
        DJSystem.AudioZones[zoneId] = nil
        
        triggerCallbacks('zone', 'deleted', zoneId)
        DJUtils.Info("Zone deleted: %s", zoneId)
        return true
    end
    
    return false
end

-- Adicionar speaker à zona
-- @param zoneId string - ID da zona
-- @param speaker number - Entidade do speaker
function DJState.AddSpeaker(zoneId, speaker)
    if DJSystem.AudioZones[zoneId] then
        table.insert(DJSystem.AudioZones[zoneId].speakers, speaker)
        
        triggerCallbacks('zone', 'speaker_added', zoneId, speaker)
        DJUtils.Info("Speaker added to zone %s: %d", zoneId, speaker)
        return true
    end
    
    return false
end

-- Remover speaker da zona
-- @param zoneId string - ID da zona
-- @param speaker number - Entidade do speaker
function DJState.RemoveSpeaker(zoneId, speaker)
    if DJSystem.AudioZones[zoneId] then
        for i, spk in ipairs(DJSystem.AudioZones[zoneId].speakers) do
            if spk == speaker then
                table.remove(DJSystem.AudioZones[zoneId].speakers, i)
                
                triggerCallbacks('zone', 'speaker_removed', zoneId, speaker)
                DJUtils.Info("Speaker removed from zone %s: %d", zoneId, speaker)
                return true
            end
        end
    end
    
    return false
end

-- Obter zona
-- @param zoneId string - ID da zona
-- @return table - Dados da zona
function DJState.GetZone(zoneId)
    if DJSystem.AudioZones[zoneId] then
        return DJUtils.DeepCopy(DJSystem.AudioZones[zoneId])
    end
    return nil
end

-- Verificar se música está tocando na zona
-- @param zoneId string - ID da zona
-- @return boolean - Se está tocando
function DJState.IsMusicPlayingInZone(zoneId)
    -- Por enquanto usa estado global, mas pode ser por zona no futuro
    return DJSystem.MusicBeat.isPlaying
end

-- ============================================
-- PROPS STATE
-- ============================================

-- Registrar prop spawnado
-- @param entity number - Entidade
-- @param model string - Modelo
-- @param coords vector3 - Coordenadas
-- @param heading number - Heading
function DJState.RegisterProp(entity, model, coords, heading)
    DJSystem.SpawnedProps[entity] = {
        model = model,
        coords = coords,
        heading = heading,
        spawnedAt = GetGameTimer()
    }
    
    triggerCallbacks('prop', 'spawned', entity, model, coords, heading)
    DJUtils.Info("Prop registered: Entity=%d, Model=%s", entity, model)
end

-- Remover prop
-- @param entity number - Entidade
function DJState.UnregisterProp(entity)
    if DJSystem.SpawnedProps[entity] then
        local prop = DJSystem.SpawnedProps[entity]
        DJSystem.SpawnedProps[entity] = nil
        
        triggerCallbacks('prop', 'removed', entity, prop.model)
        DJUtils.Info("Prop unregistered: Entity=%d", entity)
        return true
    end
    
    return false
end

-- Obter prop
-- @param entity number - Entidade
-- @return table - Dados do prop
function DJState.GetProp(entity)
    if DJSystem.SpawnedProps[entity] then
        return DJUtils.DeepCopy(DJSystem.SpawnedProps[entity])
    end
    return nil
end

-- ============================================
-- UI STATE
-- ============================================

-- Atualizar estado da UI
-- @param isOpen boolean - Se está aberta
-- @param mode string - Modo ('dj', 'builder', 'playlist')
-- @param currentZone string - Zona atual (opcional)
function DJState.SetUIState(isOpen, mode, currentZone)
    local oldState = DJSystem.UI.isOpen
    
    DJSystem.UI.isOpen = isOpen
    DJSystem.UI.mode = mode
    if currentZone then
        DJSystem.UI.currentZone = currentZone
    end
    
    if oldState ~= isOpen then
        triggerCallbacks('ui', isOpen and 'opened' or 'closed', mode, currentZone)
        DJUtils.Info("UI %s: Mode=%s, Zone=%s", isOpen and "opened" or "closed", 
            tostring(mode), tostring(currentZone))
    end
end

-- Obter estado da UI
-- @return table - Estado da UI
function DJState.GetUIState()
    return DJUtils.DeepCopy(DJSystem.UI)
end

-- ============================================
-- PLAYLIST STATE
-- ============================================

-- Atualizar playlist
-- @param playlist table - Dados da playlist
function DJState.SetPlaylist(playlist)
    if playlist.name then DJSystem.Playlist.name = playlist.name end
    if playlist.tracks then DJSystem.Playlist.tracks = playlist.tracks end
    if playlist.currentIndex then DJSystem.Playlist.currentIndex = playlist.currentIndex end
    if playlist.shuffle ~= nil then DJSystem.Playlist.shuffle = playlist.shuffle end
    if playlist.repeat ~= nil then DJSystem.Playlist.repeat = playlist.repeat end
    
    triggerCallbacks('playlist', 'updated', DJSystem.Playlist)
    DJUtils.Info("Playlist updated: %s (%d tracks)", DJSystem.Playlist.name, #DJSystem.Playlist.tracks)
end

-- Obter playlist
-- @return table - Playlist atual
function DJState.GetPlaylist()
    return DJUtils.DeepCopy(DJSystem.Playlist)
end

-- ============================================
-- DEBUG E ESTATÍSTICAS
-- ============================================

-- Obter estatísticas do sistema
-- @return table - Estatísticas
function DJState.GetStats()
    local effectCount = 0
    for _, entity in pairs(DJSystem.ActiveEffects) do
        effectCount = effectCount + DJUtils.TableCount(entity.effects)
    end
    
    return {
        zones = DJUtils.TableCount(DJSystem.AudioZones),
        props = DJUtils.TableCount(DJSystem.SpawnedProps),
        effects = effectCount,
        musicPlaying = DJSystem.MusicBeat.isPlaying,
        bpm = DJSystem.MusicBeat.bpm,
        uiOpen = DJSystem.UI.isOpen,
        playlistTracks = #DJSystem.Playlist.tracks
    }
end

-- Imprimir estatísticas
function DJState.PrintStats()
    local stats = DJState.GetStats()
    print("========================================")
    print("[DJ State] System Statistics")
    print("========================================")
    print(string.format("Zones: %d", stats.zones))
    print(string.format("Props: %d", stats.props))
    print(string.format("Effects: %d", stats.effects))
    print(string.format("Music: %s (BPM: %d)", stats.musicPlaying and "Playing" or "Stopped", stats.bpm))
    print(string.format("UI: %s", stats.uiOpen and "Open" or "Closed"))
    print(string.format("Playlist: %d tracks", stats.playlistTracks))
    print("========================================")
end

-- ============================================
-- ALIASES PARA COMPATIBILIDADE
-- ============================================

-- Aliases para funções antigas (será removido na v3.0)
DJIsOnBeat = DJState.IsOnBeat
DJGetBeatPhase = DJState.GetBeatPhase
DJIsMusicPlayingInZone = function(entity) return DJState.IsMusicPlayingInZone(DJSystem.UI.currentZone) end
DJIsEffectActive = DJState.IsEffectActive
DJInitEffect = DJState.AddEffect
DJRemoveEffect = DJState.RemoveEffect
DJUpdateMusicBeat = DJState.SetMusicBeat

print("[DJ State] ✓ State management module loaded successfully")
