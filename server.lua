-- Audio Zones System
local audioZones = {}
-- Structure: audioZones[zoneId] = { 
--   djTable = netId, 
--   speakers = {netId1, netId2, ...},
--   effects = {netId1, netId2, ...},
--   deck_a = { url = nil, playing = false, startTime = 0 },
--   deck_b = { url = nil, playing = false, startTime = 0 }
-- }

-- Persistent Props Storage
local persistentProps = {}
-- Structure: persistentProps[netId] = { model, coords, heading, propType, zoneId, effectConfigs }

-- Generate unique zone ID
function GenerateZoneId()
    return string.format("zone_%d_%d", os.time(), math.random(1000, 9999))
end

-- Sync Audio Events (Zone-based)
RegisterNetEvent('dj:syncAudio')
AddEventHandler('dj:syncAudio', function(data)
    local src = source
    local zoneId = data.zoneId
    
    if not zoneId or not audioZones[zoneId] then
        print("[DJ Server] Error: Invalid zone ID: " .. tostring(zoneId))
        return
    end
    
    local deckKey = 'deck_' .. data.deck
    if not audioZones[zoneId][deckKey] then
        print("[DJ Server] Error: Invalid deck: " .. tostring(data.deck))
        return
    end
    
    if data.action == 'play' then
        audioZones[zoneId][deckKey].url = data.url
        audioZones[zoneId][deckKey].playing = true
        audioZones[zoneId][deckKey].startTime = os.time()
        
        -- Broadcast to all clients with zone info
        TriggerClientEvent('dj:playAudio', -1, zoneId, data.deck, data.url, 0)
        print(string.format("[DJ Server] Playing %s in zone %s", data.deck, zoneId))
    elseif data.action == 'stop' then
        audioZones[zoneId][deckKey].playing = false
        TriggerClientEvent('dj:stopAudio', -1, zoneId, data.deck)
    elseif data.action == 'pause' then
        audioZones[zoneId][deckKey].playing = false
        TriggerClientEvent('dj:pauseAudio', -1, zoneId, data.deck)
    end
end)

RegisterNetEvent('dj:syncVolume')
AddEventHandler('dj:syncVolume', function(data)
    TriggerClientEvent('dj:updateDeckVolume', -1, data.deck, data.volume)
end)

-- Spawn Props (Server-Side)
RegisterNetEvent('dj:spawnProp')
AddEventHandler('dj:spawnProp', function(data)
    local src = source
    local coords = data.coords
    local heading = data.heading
    local model = data.prop
    
    -- Create object server-side (requires OneSync)
    local obj = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, true, true, false)
    
    -- Wait for entity to exist
    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if DoesEntityExist(obj) then
        SetEntityHeading(obj, heading)
        FreezeEntityPosition(obj, true)
        
        -- Make entity persistent (server-side only has limited natives)
        local netId = NetworkGetNetworkIdFromEntity(obj)
        
        -- Set routing bucket to ensure visibility
        SetEntityRoutingBucket(obj, 0)
        
        -- Set state bags BEFORE notifying clients
        if model == 'prop_dj_deck_01' then
            local zoneId = GenerateZoneId()
            Entity(obj).state:set('zoneId', zoneId, true) -- Force replicate
            Entity(obj).state:set('propType', 'dj_table', true)
            
            -- Initialize zone
            audioZones[zoneId] = {
                djTable = netId,
                speakers = {},
                effects = {},
                deck_a = { url = nil, playing = false, startTime = 0 },
                deck_b = { url = nil, playing = false, startTime = 0 }
            }
            
            print(string.format("[DJ Server] ✓ Created zone %s for DJ table (netId: %d, entity: %d)", zoneId, netId, obj))
        elseif model == 'prop_speaker_06' or 
               model == 'prop_speaker_05' or 
               model == 'prop_speaker_08' then
            Entity(obj).state:set('propType', 'speaker', true)
            Entity(obj).state:set('zoneId', nil, true) -- Will be set when linked
            print(string.format("[DJ Server] ✓ Created speaker (netId: %d, entity: %d, unlinked)", netId, obj))
        else
            print(string.format("[DJ Server] ✓ Created prop %s (netId: %d, entity: %d)", model, netId, obj))
        end
        
        -- Set Effect Configuration State Bag (MULTIPLE EFFECTS SUPPORT)
        if data.effectConfig then
            -- Initialize with first effect
            local effectConfigs = {
                effect1 = data.effectConfig
            }
            Entity(obj).state:set('effectConfigs', effectConfigs, true)
            print(string.format("[DJ Server] ✓ Effect config set: %s", data.effectConfig.type))
        elseif data.effect and data.effect ~= 'none' then
            -- Backward compatibility with old system
            Entity(obj).state:set('effect', data.effect, true)
        end
        
        -- PERSISTÊNCIA: Salvar prop para restaurar após restart
        persistentProps[netId] = {
            model = model,
            coords = coords,
            heading = heading,
            propType = Entity(obj).state.propType,
            zoneId = Entity(obj).state.zoneId,
            effectConfigs = Entity(obj).state.effectConfigs
        }
        
        -- Wait a bit for state bags to replicate
        Wait(100)
        
        -- Notify all clients about the new prop
        TriggerClientEvent('dj:propSpawned', -1, netId)
        print(string.format("[DJ Server] Notified clients about prop spawn (netId: %d)", netId))
        print(string.format("[DJ Server] ✓ Prop saved to persistent storage (total: %d)", CountTable(persistentProps)))
    end
end)

-- Helper function to count table entries
function CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Remove Specific Prop
RegisterNetEvent('dj:removeSpecificProp')
AddEventHandler('dj:removeSpecificProp', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        local propType = Entity(entity).state.propType
        local zoneId = Entity(entity).state.zoneId
        
        print(string.format("[DJ Server] Removing prop - NetId: %d, Type: %s, Zone: %s", netId, tostring(propType), tostring(zoneId)))
        
        -- QUEBRAR LINKS: Remove prop de todas as zonas
        if propType == 'dj_table' and zoneId and audioZones[zoneId] then
            -- Remover DJ table: deslinkar todos os speakers e effects
            print(string.format("[DJ Server] Removing DJ table - unlinking %d speakers and %d effects", 
                #audioZones[zoneId].speakers, #audioZones[zoneId].effects))
            
            -- Deslinkar speakers
            for _, speakerNetId in ipairs(audioZones[zoneId].speakers) do
                local speakerEntity = NetworkGetEntityFromNetworkId(speakerNetId)
                if DoesEntityExist(speakerEntity) then
                    Entity(speakerEntity).state:set('zoneId', nil, true)
                    TriggerClientEvent('dj:speakerUnlinked', -1, speakerNetId)
                end
            end
            
            -- Deslinkar effects
            for _, effectNetId in ipairs(audioZones[zoneId].effects) do
                local effectEntity = NetworkGetEntityFromNetworkId(effectNetId)
                if DoesEntityExist(effectEntity) then
                    Entity(effectEntity).state:set('zoneId', nil, true)
                    TriggerClientEvent('dj:effectUnlinked', -1, effectNetId)
                end
            end
            
            -- PARAR MÚSICA: Parar todos os decks da zona
            TriggerClientEvent('dj:stopAudio', -1, zoneId, 'a')
            TriggerClientEvent('dj:stopAudio', -1, zoneId, 'b')
            print(string.format("[DJ Server] ✓ Music stopped for zone %s", zoneId))
            
            -- Remover zona
            audioZones[zoneId] = nil
            print(string.format("[DJ Server] ✓ Zone %s removed", zoneId))
            
        elseif propType == 'speaker' and zoneId then
            -- Remover speaker: deslinkar da zona
            if audioZones[zoneId] then
                for i, speakerNetId in ipairs(audioZones[zoneId].speakers) do
                    if speakerNetId == netId then
                        table.remove(audioZones[zoneId].speakers, i)
                        print(string.format("[DJ Server] ✓ Speaker unlinked from zone %s", zoneId))
                        break
                    end
                end
            end
            TriggerClientEvent('dj:speakerUnlinked', -1, netId)
            
        elseif propType == 'effect' and zoneId then
            -- Remover effect: deslinkar da zona
            if audioZones[zoneId] then
                for i, effectNetId in ipairs(audioZones[zoneId].effects) do
                    if effectNetId == netId then
                        table.remove(audioZones[zoneId].effects, i)
                        print(string.format("[DJ Server] ✓ Effect unlinked from zone %s", zoneId))
                        break
                    end
                end
            end
            TriggerClientEvent('dj:effectUnlinked', -1, netId)
        end
        
        -- PERSISTÊNCIA: Remover do storage
        if persistentProps[netId] then
            persistentProps[netId] = nil
            print(string.format("[DJ Server] ✓ Prop removed from persistent storage (remaining: %d)", CountTable(persistentProps)))
        end
        
        -- Deletar entidade
        DeleteEntity(entity)
        print(string.format("[DJ Server] ✓ Prop deleted (NetId: %d)", netId))
    end
end)

-- Link Speaker to Zone
RegisterNetEvent('dj:linkSpeaker')
AddEventHandler('dj:linkSpeaker', function(speakerNetId, zoneId)
    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)
    
    if not DoesEntityExist(speaker) then
        print("[DJ] Error: Speaker doesn't exist")
        return
    end
    
    if not audioZones[zoneId] then
        print("[DJ] Error: Zone doesn't exist")
        return
    end
    
    -- Link speaker to zone
    Entity(speaker).state.zoneId = zoneId
    table.insert(audioZones[zoneId].speakers, speakerNetId)
    
    print(string.format("[DJ] Linked speaker to zone %s (total: %d speakers)", zoneId, #audioZones[zoneId].speakers))
    
    -- Notify all clients
    TriggerClientEvent('dj:speakerLinked', -1, speakerNetId, zoneId)
end)

-- Unlink Speaker from Zone
RegisterNetEvent('dj:unlinkSpeaker')
AddEventHandler('dj:unlinkSpeaker', function(speakerNetId)
    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)
    
    if not DoesEntityExist(speaker) then return end
    
    local zoneId = Entity(speaker).state.zoneId
    if zoneId and audioZones[zoneId] then
        -- Remove from zone's speaker list
        for i, netId in ipairs(audioZones[zoneId].speakers) do
            if netId == speakerNetId then
                table.remove(audioZones[zoneId].speakers, i)
                break
            end
        end
    end
    
    Entity(speaker).state.zoneId = nil
    TriggerClientEvent('dj:speakerUnlinked', -1, speakerNetId)
end)

-- Link Effect to Zone
RegisterNetEvent('dj:linkEffect')
AddEventHandler('dj:linkEffect', function(effectNetId, zoneId)
    local effect = NetworkGetEntityFromNetworkId(effectNetId)
    
    if not DoesEntityExist(effect) then 
        print("[DJ Server] Error: Effect doesn't exist")
        return 
    end
    
    if not audioZones[zoneId] then 
        print("[DJ Server] Error: Zone doesn't exist")
        return 
    end
    
    -- Initialize effects table if it doesn't exist
    if not audioZones[zoneId].effects then
        audioZones[zoneId].effects = {}
    end
    
    -- Link effect to zone
    Entity(effect).state.zoneId = zoneId
    Entity(effect).state.propType = 'effect'
    table.insert(audioZones[zoneId].effects, effectNetId)
    
    -- IMPORTANT: Ensure effectConfigs exists (for props spawned before update)
    local currentConfigs = Entity(effect).state.effectConfigs
    if not currentConfigs or type(currentConfigs) ~= 'table' then
        -- Check if old effectConfig exists
        local oldConfig = Entity(effect).state.effectConfig
        if oldConfig and oldConfig.type and oldConfig.type ~= 'none' then
            print("[DJ Server] Converting old effectConfig to effectConfigs for linked prop")
            Entity(effect).state:set('effectConfigs', { effect1 = oldConfig }, true)
        else
            print("[DJ Server] WARNING: Linked effect has no configuration!")
        end
    end
    
    print(string.format("[DJ Server] Linked effect to zone %s (total: %d effects)", zoneId, #audioZones[zoneId].effects))
    
    -- Notify all clients
    TriggerClientEvent('dj:effectLinked', -1, effectNetId, zoneId)
end)

-- Unlink Effect from Zone
RegisterNetEvent('dj:unlinkEffect')
AddEventHandler('dj:unlinkEffect', function(effectNetId)
    local effect = NetworkGetEntityFromNetworkId(effectNetId)
    
    if not DoesEntityExist(effect) then return end
    
    local zoneId = Entity(effect).state.zoneId
    if zoneId and audioZones[zoneId] and audioZones[zoneId].effects then
        -- Remove from zone's effect list
        for i, netId in ipairs(audioZones[zoneId].effects) do
            if netId == effectNetId then
                table.remove(audioZones[zoneId].effects, i)
                print(string.format("[DJ Server] Unlinked effect from zone %s", zoneId))
                break
            end
        end
    end
    
    Entity(effect).state.zoneId = nil
    Entity(effect).state.propType = nil
    TriggerClientEvent('dj:effectUnlinked', -1, effectNetId)
end)

-- Visual Effects (One-off)
RegisterNetEvent('dj:spawnVisual')
AddEventHandler('dj:spawnVisual', function(data)
    TriggerClientEvent('dj:spawnVisualClient', -1, data.visual, source)
end)

-- Sync for new players (and restore props after restart)
RegisterNetEvent('dj:requestSync')
AddEventHandler('dj:requestSync', function()
    local src = source
    
    print(string.format("[DJ Server] Player %d requesting sync - %d persistent props available", src, CountTable(persistentProps)))
    
    -- RESTAURAR PROPS PERSISTENTES
    for netId, propData in pairs(persistentProps) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        -- Se a entidade não existe mais, recriar
        if not DoesEntityExist(entity) then
            print(string.format("[DJ Server] Restoring prop: %s (NetId: %d)", propData.model, netId))
            
            -- Recriar prop
            local obj = CreateObject(GetHashKey(propData.model), propData.coords.x, propData.coords.y, propData.coords.z, true, true, false)
            
            if DoesEntityExist(obj) then
                SetEntityHeading(obj, propData.heading)
                FreezeEntityPosition(obj, true)
                SetEntityRoutingBucket(obj, 0)
                
                local newNetId = NetworkGetNetworkIdFromEntity(obj)
                
                -- Restaurar state bags
                if propData.propType then
                    Entity(obj).state:set('propType', propData.propType, true)
                end
                if propData.zoneId then
                    Entity(obj).state:set('zoneId', propData.zoneId, true)
                end
                if propData.effectConfigs then
                    Entity(obj).state:set('effectConfigs', propData.effectConfigs, true)
                end
                
                -- Atualizar netId no storage
                persistentProps[newNetId] = propData
                persistentProps[netId] = nil
                
                -- Notificar cliente
                TriggerClientEvent('dj:propSpawned', src, newNetId)
                
                print(string.format("[DJ Server] ✓ Prop restored (new NetId: %d)", newNetId))
            end
        else
            -- Prop já existe, apenas notificar cliente
            TriggerClientEvent('dj:propSpawned', src, netId)
        end
    end
    
    -- Send all active zones and their audio to the new player
    for zoneId, zone in pairs(audioZones) do
        for deck, info in pairs({a = zone.deck_a, b = zone.deck_b}) do
            if info.playing and info.url then
                local timeDiff = os.time() - info.startTime
                TriggerClientEvent('dj:playAudio', src, zoneId, deck, info.url, timeDiff)
            end
        end
        
        -- Send music state if available
        if zone.musicState then
            TriggerClientEvent('dj:syncMusicState', src, zoneId, zone.musicState)
        end
    end
    
    print(string.format("[DJ Server] ✓ Sync completed for player %d", src))
end)

-- Broadcast beat to all players in zone
RegisterNetEvent('dj:broadcastBeat')
AddEventHandler('dj:broadcastBeat', function(zoneId, bpm)
    local source = source
    print("========================================")
    print(string.format("[DJ Server] 📡 BROADCAST BEAT REQUEST from player %d", source))
    print(string.format("[DJ Server] Zone: %s | BPM: %d", tostring(zoneId), bpm))
    
    if not audioZones[zoneId] then 
        print(string.format("[DJ Server] ⚠️ Zone %s not found!", tostring(zoneId)))
        print("[DJ Server] Available zones:", json.encode(audioZones))
        print("========================================")
        return 
    end
    
    print("[DJ Server] ✓ Zone found, broadcasting to all clients...")
    
    -- Broadcast to all clients
    TriggerClientEvent('dj:receiveBeat', -1, zoneId, bpm)
    
    print(string.format("[DJ Server] ✓ Beat broadcasted - Zone: %s, BPM: %d", zoneId, bpm))
    print("========================================")
end)

-- Update music state for zone
RegisterNetEvent('dj:updateMusicState')
AddEventHandler('dj:updateMusicState', function(zoneId, playing, bpm)
    if not audioZones[zoneId] then return end
    
    audioZones[zoneId].musicState = {
        playing = playing,
        bpm = bpm,
        lastUpdate = os.time()
    }
    
    -- Broadcast to all clients
    TriggerClientEvent('dj:syncMusicState', -1, zoneId, audioZones[zoneId].musicState)
    
    print(string.format("[DJ Server] Music state updated for zone %s - BPM: %d", zoneId, bpm))
end)

-- Add Effect to Prop (MULTIPLE EFFECTS SUPPORT)
RegisterNetEvent('dj:addEffect')
AddEventHandler('dj:addEffect', function(netId, effectConfig)
    local prop = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(prop) then 
        print("[DJ Server] Error: Prop doesn't exist")
        return 
    end
    
    -- Get current effects
    local currentEffects = Entity(prop).state.effectConfigs or {}
    
    -- Generate new effect ID
    local effectId = string.format("effect%d", os.time() + math.random(1, 9999))
    
    -- Add new effect
    currentEffects[effectId] = effectConfig
    
    -- Update state bag
    Entity(prop).state:set('effectConfigs', currentEffects, true)
    
    print(string.format("[DJ Server] Effect added - NetId: %d, EffectID: %s, Type: %s", netId, effectId, effectConfig.type))
end)

-- Remove Effect from Prop
RegisterNetEvent('dj:removeEffect')
AddEventHandler('dj:removeEffect', function(netId, effectId)
    local prop = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(prop) then 
        print("[DJ Server] Error: Prop doesn't exist")
        return 
    end
    
    -- Get current effects
    local currentEffects = Entity(prop).state.effectConfigs or {}
    
    -- Remove effect
    currentEffects[effectId] = nil
    
    -- Update state bag
    Entity(prop).state:set('effectConfigs', currentEffects, true)
    
    print(string.format("[DJ Server] Effect removed - NetId: %d, EffectID: %s", netId, effectId))
end)

-- Update Effect Configuration
RegisterNetEvent('dj:updateEffect')
AddEventHandler('dj:updateEffect', function(netId, effectId, newConfig)
    local prop = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(prop) then 
        print("[DJ Server] Error: Prop doesn't exist")
        return 
    end
    
    -- Get current effects
    local currentEffects = Entity(prop).state.effectConfigs or {}
    
    -- Update effect
    currentEffects[effectId] = newConfig
    
    -- Update state bag
    Entity(prop).state:set('effectConfigs', currentEffects, true)
    
    print(string.format("[DJ Server] Effect updated - NetId: %d, EffectID: %s, Type: %s", netId, effectId, newConfig.type))
end)
