print("[DJ] ========================================")
print("[DJ] Client.lua loading...")
print("[DJ] ========================================")

local isUiOpen = false
local spawnedProps = {}
local audioZones = {} -- Structure: audioZones[zoneId] = { djTable = entity, speakers = {entity1, entity2, ...}, effects = {entity1, entity2, ...} }
local djPosition = nil 
local placementMode = false
local editMode = false
local selectedProp = nil
local ghostProp = nil
local ghostModel = nil
local currentDJZone = nil -- Zone ID of the DJ table the player is currently using

-- Music Beat State (MUST BE DEFINED EARLY!)
local musicBeat = {
    bpm = 128,
    beat = 0,
    intensity = 0.5,
    lastBeatTime = 0,
    isPlaying = false
}

-- Active Effects Tracking
-- activeEffects[entity] = { effects = { [effectId] = { thread = thread, config = config } } }
local activeEffects = {}

-- Gizmo State
local gizmoState = {
    activeAxis = nil, -- 'x', 'y', 'z', 'rot'
    lastMouseX = 0,
    lastMouseY = 0
}

-- Key mapping
RegisterKeyMapping('opendjbuilder', 'Open DJ Stage Builder', 'keyboard', 'F6')

RegisterCommand('opendjbuilder', function()
    if not isUiOpen and not placementMode and not editMode then
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'toggle', status = true, mode = 'builder' })
        isUiOpen = true
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = 'toggle', status = false })
    isUiOpen = false
    placementMode = false
    currentDJZone = nil
    
    if ghostProp then
        if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
        ghostProp = nil
    end
    
    cb('ok')
    print("[DJ] UI Closed - Focus Released")
end)

-- Music Beat Callback
RegisterNUICallback('musicBeat', function(data, cb)
    print("========================================")
    print("[DJ Beat] 📥 BEAT CALLBACK RECEIVED!")
    print("[DJ Beat] Raw data:", json.encode(data))
    
    musicBeat.bpm = data.bpm or 128
    musicBeat.lastBeatTime = GetGameTimer()
    musicBeat.beat = data.beat or ((musicBeat.beat + 1) % 4)
    musicBeat.isPlaying = true
    
    print(string.format("[DJ Beat] ✓ Beat processed: %d/4 | BPM: %d | Time: %d", 
        musicBeat.beat, musicBeat.bpm, GetGameTimer()))
    print(string.format("[DJ Beat] Current zone: %s", tostring(currentDJZone)))
    
    -- Broadcast beat to all clients in the zone
    if currentDJZone then
        print(string.format("[DJ Beat] 📡 Broadcasting to zone: %s", currentDJZone))
        TriggerServerEvent('dj:broadcastBeat', currentDJZone, data.bpm)
        print("[DJ Beat] ✓ Broadcast sent to server")
    else
        print("[DJ Beat] ⚠️ WARNING: No current DJ zone set!")
        print("[DJ Beat] Beat will NOT be broadcasted to other clients")
        print("[DJ Beat] Make sure you opened the DJ interface from a DJ table")
    end
    
    print("========================================")
    
    cb('ok')
end)

-- Music State Update Callback
RegisterNUICallback('updateMusicState', function(data, cb)
    musicBeat.isPlaying = data.playing
    musicBeat.bpm = data.bpm or 128
    
    if currentDJZone then
        TriggerServerEvent('dj:updateMusicState', currentDJZone, data.playing, data.bpm)
    end
    
    print(string.format("[DJ Music] State updated - Playing: %s, BPM: %d", tostring(data.playing), data.bpm))
    cb('ok')
end)

RegisterNUICallback('startPlacement', function(data, cb)
    print("[DJ] ========================================")
    print("[DJ] startPlacement callback RECEIVED!")
    print("[DJ] Data type:", type(data))
    print("[DJ] Data.prop:", tostring(data.prop))
    print("[DJ] Full data:", json.encode(data))
    print("[DJ] ========================================")
    
    -- Close NUI first
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = 'toggle', status = false })
    isUiOpen = false
    
    -- Start placement (aceita 'prop' ou 'propName')
    local propModel = data.prop or data.propName
    print(string.format("[DJ] Starting placement for: %s", tostring(propModel)))
    
    if not propModel then
        print("[DJ] ERROR: No prop model received!")
        cb('error')
        return
    end
    
    StartGhostPlacement(propModel)
    
    cb('ok')
end)

print("[DJ] ✓ startPlacement callback registered")

RegisterNUICallback('confirmPlacement', function(data, cb)
    SetNuiFocus(false, false)
    print("[DJ] Confirm placement with config:", json.encode(data.effectConfig))
    TriggerServerEvent('dj:spawnProp', data)
    if ghostProp then
        if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
        ghostProp = nil
    end
    cb('ok')
end)

-- Reconfigure existing effect (DEPRECATED - use updateEffect instead)
RegisterNUICallback('reconfigureEffect', function(data, cb)
    SetNuiFocus(false, false)
    print("[DJ] Reconfiguring effect - NetId:", data.netId)
    print("[DJ] New config:", json.encode(data.effectConfig))
    
    -- Send to server to update state bag
    TriggerServerEvent('dj:reconfigureEffect', data.netId, data.effectConfig)
    
    cb('ok')
end)

-- Add effect to existing prop (MULTIPLE EFFECTS SYSTEM)
RegisterNUICallback('addEffect', function(data, cb)
    SetNuiFocus(false, false)
    print("[DJ] Adding effect - NetId:", data.netId)
    print("[DJ] Effect config:", json.encode(data.effectConfig))
    
    TriggerServerEvent('dj:addEffect', data.netId, data.effectConfig)
    
    cb('ok')
end)

-- Remove effect from prop
RegisterNUICallback('removeEffect', function(data, cb)
    print("[DJ] Removing effect - NetId:", data.netId, "EffectID:", data.effectId)
    
    TriggerServerEvent('dj:removeEffect', data.netId, data.effectId)
    
    cb('ok')
end)

-- Update effect configuration
RegisterNUICallback('updateEffect', function(data, cb)
    SetNuiFocus(false, false)
    print("[DJ] Updating effect - NetId:", data.netId, "EffectID:", data.effectId)
    print("[DJ] New config:", json.encode(data.effectConfig))
    
    TriggerServerEvent('dj:updateEffect', data.netId, data.effectId, data.effectConfig)
    
    cb('ok')
end)

RegisterCommand('djfix', function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    isUiOpen = false
    placementMode = false
    if ghostProp then
        if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
        ghostProp = nil
    end
    print("[DJ] UI Focus Reset")
end)

-- Debug command to test beat system
RegisterCommand('djbeattest', function(source, args)
    local bpm = tonumber(args[1]) or 128
    
    print("========================================")
    print("[DJ Beat Test] Testing beat system")
    print("[DJ Beat Test] BPM:", bpm)
    print("[DJ Beat Test] Current state:")
    print("  - isPlaying:", musicBeat.isPlaying)
    print("  - BPM:", musicBeat.bpm)
    print("  - Last beat time:", musicBeat.lastBeatTime)
    print("  - Current time:", GetGameTimer())
    print("  - Time since beat:", GetGameTimer() - musicBeat.lastBeatTime, "ms")
    print("  - IsOnBeat():", IsOnBeat())
    print("  - Beat phase:", GetBeatPhase())
    print("========================================")
    
    -- Simulate a beat
    musicBeat.bpm = bpm
    musicBeat.lastBeatTime = GetGameTimer()
    musicBeat.isPlaying = true
    musicBeat.beat = (musicBeat.beat + 1) % 4
    
    print("[DJ Beat Test] ✓ Simulated beat sent!")
    print("[DJ Beat Test] Next beat in:", (60000 / bpm), "ms")
end)

-- Debug command to check NUI beat system state
RegisterCommand('djbeatcheck', function()
    print("========================================")
    print("[DJ Beat Check] Requesting NUI beat system state...")
    SendNUIMessage({
        type = 'checkBeatSystem'
    })
    print("[DJ Beat Check] Check request sent to NUI")
    print("========================================")
end)

-- Debug command to show beat info
RegisterCommand('djbeatinfo', function()
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < 10000 do -- Show for 10 seconds
            local onBeat = IsOnBeat()
            local beatPhase = GetBeatPhase()
            local timeSinceBeat = GetGameTimer() - musicBeat.lastBeatTime
            
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextEntry("STRING")
            
            local color = onBeat and "~g~" or "~w~"
            local beatIndicator = onBeat and "♪ ON BEAT ♪" or "- - - - -"
            
            AddTextComponentString(string.format(
                "%sBeat System Info~w~\n" ..
                "Playing: %s | BPM: %d | Beat: %d/4\n" ..
                "Time since beat: %dms\n" ..
                "Beat phase: %.2f\n" ..
                "%s%s",
                color,
                musicBeat.isPlaying and "~g~YES" or "~r~NO",
                musicBeat.bpm,
                musicBeat.beat,
                timeSinceBeat,
                beatPhase,
                color,
                beatIndicator
            ))
            DrawText(0.02, 0.5)
            
            Wait(0)
        end
    end)
end)

RegisterNUICallback('playAudio', function(data, cb)
    djPosition = GetEntityCoords(PlayerPedId())
    
    -- Add zone ID to the data
    if currentDJZone then
        data.zoneId = currentDJZone
        TriggerServerEvent('dj:syncAudio', data)
    else
        print("[DJ] Error: No zone ID set")
    end
    
    cb('ok')
end)

RegisterNUICallback('updateVolume', function(data, cb)
    TriggerServerEvent('dj:syncVolume', data)
    cb('ok')
end)

RegisterNUICallback('spawnVisual', function(data, cb)
    TriggerServerEvent('dj:spawnVisual', data)
    cb('ok')
end)

-- Client Event Handlers for Audio Sync (Zone-based)
RegisterNetEvent('dj:playAudio')
AddEventHandler('dj:playAudio', function(zoneId, deck, url, startTime)
    SendNUIMessage({
        type = 'playAudio',
        zoneId = zoneId,
        deck = deck,
        url = url,
        time = startTime or 0
    })
end)

RegisterNetEvent('dj:stopAudio')
AddEventHandler('dj:stopAudio', function(zoneId, deck)
    SendNUIMessage({
        type = 'stopAudio',
        zoneId = zoneId,
        deck = deck
    })
end)

RegisterNetEvent('dj:pauseAudio')
AddEventHandler('dj:pauseAudio', function(zoneId, deck)
    SendNUIMessage({
        type = 'pauseAudio',
        zoneId = zoneId,
        deck = deck
    })
end)

RegisterNetEvent('dj:updateDeckVolume')
AddEventHandler('dj:updateDeckVolume', function(deck, volume)
    SendNUIMessage({
        type = 'setDeckVolume',
        deck = deck,
        volume = volume
    })
end)

-- Handle prop spawning for persistence and zone tracking
RegisterNetEvent('dj:propSpawned')
AddEventHandler('dj:propSpawned', function(netId)
    -- Wait for entity to exist on client
    local timeout = 0
    local entity = nil
    
    while timeout < 100 do
        entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            break
        end
        Wait(50)
        timeout = timeout + 1
    end
    
    if DoesEntityExist(entity) then
        -- Set as mission entity to prevent despawn
        SetEntityAsMissionEntity(entity, true, true)
        
        -- Force entity to always be visible
        SetEntityAlpha(entity, 255, false)
        SetEntityVisible(entity, true, false)
        
        -- Keep model loaded
        local model = GetEntityModel(entity)
        if not HasModelLoaded(model) then
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
        end
        
        -- Wait longer for state bag to sync
        Wait(500)
        
        -- Wait for state bag to sync
        local propType = Entity(entity).state.propType
        local zoneId = Entity(entity).state.zoneId
        
        print(string.format("[DJ Client] Prop spawned - NetId: %d, Entity: %d, Type: %s, ZoneId: %s", netId, entity, tostring(propType), tostring(zoneId)))
        
        -- Track DJ tables, speakers, and effects by zone
        if propType == 'dj_table' and zoneId then
            if not audioZones[zoneId] then
                audioZones[zoneId] = { djTable = entity, speakers = {}, effects = {} }
            end
            audioZones[zoneId].djTable = entity
            print(string.format("[DJ Client] ✓ Tracked DJ table for zone %s (Entity: %d)", zoneId, entity))
            
            -- Debug: Show all zones
            local zoneCount = 0
            for _ in pairs(audioZones) do zoneCount = zoneCount + 1 end
            print(string.format("[DJ Client] Total zones tracked: %d", zoneCount))
        elseif propType == 'speaker' then
            -- If speaker is already linked, add to zone
            if zoneId and audioZones[zoneId] then
                table.insert(audioZones[zoneId].speakers, entity)
                print(string.format("[DJ Client] ✓ Speaker auto-added to zone %s", zoneId))
            else
                print("[DJ Client] Speaker spawned (unlinked)")
            end
        elseif propType == 'effect' then
            -- If effect is already linked, add to zone
            if zoneId and audioZones[zoneId] then
                table.insert(audioZones[zoneId].effects, entity)
                print(string.format("[DJ Client] ✓ Effect auto-added to zone %s", zoneId))
            else
                print("[DJ Client] Effect spawned (unlinked)")
            end
        end
    end
end)

-- Handle speaker linking
RegisterNetEvent('dj:speakerLinked')
AddEventHandler('dj:speakerLinked', function(speakerNetId, zoneId)
    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)
    
    if DoesEntityExist(speaker) and audioZones[zoneId] then
        -- Add speaker to zone
        table.insert(audioZones[zoneId].speakers, speaker)
        print(string.format("[DJ Client] Speaker linked to zone %s (total: %d)", zoneId, #audioZones[zoneId].speakers))
    end
end)

-- Handle speaker unlinking
RegisterNetEvent('dj:speakerUnlinked')
AddEventHandler('dj:speakerUnlinked', function(speakerNetId)
    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)
    
    -- Remove from all zones
    for zoneId, zone in pairs(audioZones) do
        for i, spk in ipairs(zone.speakers) do
            if spk == speaker then
                table.remove(zone.speakers, i)
                print(string.format("[DJ Client] Speaker unlinked from zone %s", zoneId))
                break
            end
        end
    end
end)

-- Handle effect linking
RegisterNetEvent('dj:effectLinked')
AddEventHandler('dj:effectLinked', function(effectNetId, zoneId)
    local effect = NetworkGetEntityFromNetworkId(effectNetId)
    
    if DoesEntityExist(effect) and audioZones[zoneId] then
        -- Add effect to zone
        table.insert(audioZones[zoneId].effects, effect)
        print(string.format("[DJ Client] Effect linked to zone %s (total: %d)", zoneId, #audioZones[zoneId].effects))
    end
end)

-- Handle effect unlinking
RegisterNetEvent('dj:effectUnlinked')
AddEventHandler('dj:effectUnlinked', function(effectNetId)
    local effect = NetworkGetEntityFromNetworkId(effectNetId)
    
    -- Remove from all zones
    for zoneId, zone in pairs(audioZones) do
        for i, eff in ipairs(zone.effects) do
            if eff == effect then
                table.remove(zone.effects, i)
                print(string.format("[DJ Client] Effect unlinked from zone %s", zoneId))
                break
            end
        end
    end
end)


-- Simplified Placement Logic (E Key Confirmation)
function StartGhostPlacement(modelName)
    if placementMode then 
        print("[DJ] Already in placement mode")
        return 
    end
    
    placementMode = true
    ghostModel = modelName
    
    print(string.format("[DJ] StartGhostPlacement called for: %s", modelName))
    
    Citizen.CreateThread(function()
        local hash = GetHashKey(modelName)
        print(string.format("[DJ] Model hash: %d", hash))
        
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 100 do 
            Wait(10)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(hash) then
            print("[DJ] ERROR: Failed to load model!")
            placementMode = false
            return
        end
        
        print("[DJ] Model loaded successfully")
        
        -- Create ghost prop
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3.0
        ghostProp = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
        
        if not DoesEntityExist(ghostProp) then
            print("[DJ] ERROR: Failed to create ghost prop!")
            placementMode = false
            return
        end
        
        print(string.format("[DJ] Ghost prop created: %d", ghostProp))
        
        SetEntityAlpha(ghostProp, 200, false)
        SetEntityCollision(ghostProp, false, false)
        FreezeEntityPosition(ghostProp, true)
        
        local heading = 0.0
        local zOffset = 0.0
        local selectedEffect = 'none'
        local showingEffectMenu = false
        
        while placementMode do
            Wait(0)
            
            if not showingEffectMenu then
                -- Placement Mode
                local hit, hitCoords, _, _, _ = RayCastGamePlayCamera(20.0)
                
                if hit then
                    -- Update Prop Position
                    SetEntityCoords(ghostProp, hitCoords.x, hitCoords.y, hitCoords.z + zOffset)
                    SetEntityHeading(ghostProp, heading)
                    
                    -- Scroll to Rotate
                    if IsControlPressed(0, 14) then heading = heading - 2.0 end
                    if IsControlPressed(0, 15) then heading = heading + 2.0 end
                    
                    -- Arrow Keys for Height
                    if IsControlPressed(0, 172) then zOffset = zOffset + 0.02 end
                    if IsControlPressed(0, 173) then zOffset = zOffset - 0.02 end
                    
                    -- Draw Instructions
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Confirm  ~INPUT_FRONTEND_CANCEL~ Cancel\n~INPUT_WEAPON_WHEEL_NEXT~ / ~INPUT_WEAPON_WHEEL_PREV~ Rotate\n~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Height")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    -- Confirm with E
                    if IsControlJustPressed(0, 38) then -- E Key
                        local finalCoords = GetEntityCoords(ghostProp)
                        local finalHeading = GetEntityHeading(ghostProp)
                        
                        -- Se for mesa DJ, spawnar direto sem modal de efeitos
                        if ghostModel == 'prop_dj_deck_01' then
                            print("[DJ] Spawning DJ table without effect config")
                            TriggerServerEvent('dj:spawnProp', {
                                prop = ghostModel,
                                coords = finalCoords,
                                heading = finalHeading,
                                effectConfig = { type = 'none' }
                            })
                            
                            placementMode = false
                            if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
                            ghostProp = nil
                        else
                            -- Para outros props, abrir modal de configuração
                            SetNuiFocus(true, true)
                            SendNUIMessage({
                                type = 'openEffectConfig',
                                propData = {
                                    prop = ghostModel,
                                    coords = finalCoords,
                                    heading = finalHeading
                                }
                            })
                            
                            placementMode = false
                            if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
                            ghostProp = nil
                        end
                    end
                end
                
                -- Cancel
                if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 200) then -- Backspace/ESC
                    placementMode = false
                    if DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
                    ghostProp = nil
                    SetNuiFocus(true, true)
                    SendNUIMessage({ type = 'toggle', status = true, mode = 'builder' })
                    isUiOpen = true
                end
            end
        end
    end)
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = { 
        x = cameraCoord.x + direction.x * distance, 
        y = cameraCoord.y + direction.y * distance, 
        z = cameraCoord.z + direction.z * distance 
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, d, e
end

function RotationToDirection(rotation)
    local adjustedRotation = 
    { 
        x = (math.pi / 180) * rotation.x, 
        y = (math.pi / 180) * rotation.y, 
        z = (math.pi / 180) * rotation.z 
    }
    local direction = 
    { 
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        z = math.sin(adjustedRotation.x) 
    }
    return direction
end

-- Effect Linking Menu
function ShowEffectLinkMenu(effectEntity)
    local effectCoords = GetEntityCoords(effectEntity)
    local nearbyZones = {}
    
    -- Debug: Show current zones
    local zoneCount = 0
    for _ in pairs(audioZones) do zoneCount = zoneCount + 1 end
    print(string.format("[DJ] ShowEffectLinkMenu - Total zones tracked: %d", zoneCount))
    
    -- Find all DJ tables within range (200m base + 50m per linked effect)
    for zoneId, zone in pairs(audioZones) do
        if DoesEntityExist(zone.djTable) then
            local djCoords = GetEntityCoords(zone.djTable)
            local baseRange = 200.0
            local bonusRange = #zone.effects * 50.0
            local totalRange = baseRange + bonusRange
            local dist = #(effectCoords - djCoords)
            
            print(string.format("[DJ] Zone %s: Distance %.1fm, Range %.1fm", zoneId, dist, totalRange))
            
            if dist <= totalRange then
                table.insert(nearbyZones, {
                    zoneId = zoneId,
                    djTable = zone.djTable,
                    distance = dist,
                    effectCount = #zone.effects,
                    range = totalRange
                })
            end
        end
    end
    
    if #nearbyZones == 0 then
        print("[DJ] No DJ tables in range")
        return
    end
    
    -- Sort by distance
    table.sort(nearbyZones, function(a, b) return a.distance < b.distance end)
    
    -- Show menu with nearby zones
    Citizen.CreateThread(function()
        local selectedIndex = 1
        local menuActive = true
        
        while menuActive do
            Wait(0)
            DisableAllControlActions(0)
            
            -- Draw menu background
            DrawRect(0.5, 0.5, 0.3, 0.4, 0, 0, 0, 200)
            
            -- Title
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextEntry("STRING")
            AddTextComponentString("Link Effect to DJ Table")
            DrawText(0.38, 0.32)
            
            -- Instructions
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(200, 200, 200, 255)
            SetTextEntry("STRING")
            AddTextComponentString("Arrow Up/Down: Select | ENTER: Confirm | ESC: Cancel")
            DrawText(0.36, 0.65)
            
            -- List zones
            local yPos = 0.40
            for i, zone in ipairs(nearbyZones) do
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                
                if i == selectedIndex then
                    SetTextColour(0, 255, 0, 255)
                else
                    SetTextColour(255, 255, 255, 255)
                end
                
                SetTextEntry("STRING")
                AddTextComponentString(string.format("%d. DJ Table (%.1fm) - %d effects", i, zone.distance, zone.effectCount))
                DrawText(0.36, yPos)
                yPos = yPos + 0.04
            end
            
            -- Controls
            if IsDisabledControlJustPressed(0, 172) then -- Arrow Up
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #nearbyZones end
            elseif IsDisabledControlJustPressed(0, 173) then -- Arrow Down
                selectedIndex = selectedIndex + 1
                if selectedIndex > #nearbyZones then selectedIndex = 1 end
            elseif IsDisabledControlJustPressed(0, 18) then -- ENTER
                local selectedZone = nearbyZones[selectedIndex]
                TriggerServerEvent('dj:linkEffect', NetworkGetNetworkIdFromEntity(effectEntity), selectedZone.zoneId)
                menuActive = false
            elseif IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 194) then -- ESC/Backspace
                menuActive = false
            end
        end
    end)
end

-- Speaker Linking Menu
function ShowSpeakerLinkMenu(speakerEntity)
    local speakerCoords = GetEntityCoords(speakerEntity)
    local nearbyZones = {}
    
    -- Debug: Show current zones
    local zoneCount = 0
    for _ in pairs(audioZones) do zoneCount = zoneCount + 1 end
    print(string.format("[DJ] ShowSpeakerLinkMenu - Total zones tracked: %d", zoneCount))
    
    -- Find all DJ tables within range (200m base + 100m per linked speaker)
    for zoneId, zone in pairs(audioZones) do
        if DoesEntityExist(zone.djTable) then
            local djCoords = GetEntityCoords(zone.djTable)
            local baseRange = 200.0  -- Aumentado de 50m para 200m
            local bonusRange = #zone.speakers * 100.0  -- Aumentado de 50m para 100m por speaker
            local totalRange = baseRange + bonusRange
            local dist = #(speakerCoords - djCoords)
            
            print(string.format("[DJ] Zone %s: Distance %.1fm, Range %.1fm", zoneId, dist, totalRange))
            
            if dist <= totalRange then
                table.insert(nearbyZones, {
                    zoneId = zoneId,
                    djTable = zone.djTable,
                    distance = dist,
                    speakerCount = #zone.speakers,
                    range = totalRange
                })
            end
        end
    end
    
    if #nearbyZones == 0 then
        -- No DJ tables in range
        print("[DJ] No DJ tables in range")
        return
    end
    
    -- Sort by distance
    table.sort(nearbyZones, function(a, b) return a.distance < b.distance end)
    
    -- Show menu with nearby zones
    Citizen.CreateThread(function()
        local selectedIndex = 1
        local menuActive = true
        
        while menuActive do
            Wait(0)
            DisableAllControlActions(0)
            
            -- Draw menu background
            DrawRect(0.5, 0.5, 0.3, 0.4, 0, 0, 0, 200)
            
            -- Title
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextEntry("STRING")
            AddTextComponentString("Link Speaker to DJ Table")
            DrawText(0.38, 0.32)
            
            -- Instructions
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(200, 200, 200, 255)
            SetTextEntry("STRING")
            AddTextComponentString("Arrow Up/Down: Select | ENTER: Confirm | ESC: Cancel")
            DrawText(0.36, 0.65)
            
            -- List zones
            local yPos = 0.40
            for i, zone in ipairs(nearbyZones) do
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                
                if i == selectedIndex then
                    SetTextColour(0, 255, 0, 255)
                else
                    SetTextColour(255, 255, 255, 255)
                end
                
                SetTextEntry("STRING")
                AddTextComponentString(string.format("%d. DJ Table (%.1fm) - %d speakers", i, zone.distance, zone.speakerCount))
                DrawText(0.36, yPos)
                yPos = yPos + 0.04
            end
            
            -- Controls
            if IsDisabledControlJustPressed(0, 172) then -- Arrow Up
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #nearbyZones end
            elseif IsDisabledControlJustPressed(0, 173) then -- Arrow Down
                selectedIndex = selectedIndex + 1
                if selectedIndex > #nearbyZones then selectedIndex = 1 end
            elseif IsDisabledControlJustPressed(0, 18) then -- ENTER
                local selectedZone = nearbyZones[selectedIndex]
                TriggerServerEvent('dj:linkSpeaker', NetworkGetNetworkIdFromEntity(speakerEntity), selectedZone.zoneId)
                menuActive = false
            elseif IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 194) then -- ESC/Backspace
                menuActive = false
            end
        end
    end)
end

-- Helper Functions for Model Checking
local function IsSpeakerModel(model)
    local speakerHashes = {
        GetHashKey('prop_speaker_06'),
        GetHashKey('prop_speaker_05'),
        GetHashKey('prop_speaker_08')
    }
    
    for _, hash in ipairs(speakerHashes) do
        if model == hash then
            return true
        end
    end
    return false
end

local function IsEffectModel(model)
    local effectHashes = {
        GetHashKey('prop_spot_01'),
        GetHashKey('prop_worklight_03b'),
        GetHashKey('prop_worklight_04c'),
        GetHashKey('prop_air_bigradar'),
        GetHashKey('prop_air_towbar_01'),
        GetHashKey('prop_air_bigradar_l2'),
        GetHashKey('prop_tv_flat_01'),
        GetHashKey('prop_tv_flat_michael'),
        GetHashKey('prop_neon_01')
    }
    
    for _, hash in ipairs(effectHashes) do
        if model == hash then
            return true
        end
    end
    return false
end

-- Target System Integration
Citizen.CreateThread(function()
    Wait(1000)
    local models = { 
        -- DJ Equipment
        'prop_dj_deck_01', 
        'prop_speaker_06',
        'prop_speaker_05',
        'prop_speaker_08',
        
        -- Stage Lights
        'prop_spot_01',
        'prop_worklight_03b',
        'prop_worklight_04c',
        'prop_tv_flat_01',
        
        -- Effects Equipment
        'prop_air_bigradar',
        'prop_air_towbar_01',
        'prop_air_bigradar_l2',
        
        -- Bar & Furniture
        'prop_bar_stool_01',
        'prop_bar_pump_06',
        'prop_table_03',
        'prop_table_04',
        'prop_table_06',
        
        -- Decoration
        'prop_barrier_work05',
        'prop_beach_fire',
        'prop_tv_flat_michael',
        'prop_neon_01'
    }
    
    -- Effect models (for linking to DJ table)
    local effectModels = {
        'prop_spot_01',
        'prop_worklight_03b',
        'prop_worklight_04c',
        'prop_air_bigradar',
        'prop_air_towbar_01',
        'prop_air_bigradar_l2',
        'prop_tv_flat_01',
        'prop_tv_flat_michael',
        'prop_neon_01'
    }
    
    -- Speaker models (for linking to DJ table)
    local speakerModels = {
        'prop_speaker_06',
        'prop_speaker_05',
        'prop_speaker_08'
    }
    
    -- Support for ox_target
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addModel(models, {
            {
                name = 'dj_open',
                icon = 'fa-solid fa-music',
                label = 'Open DJ Decks',
                onSelect = function(data)
                    local entity = data.entity
                    local zoneId = Entity(entity).state.zoneId
                    
                    if zoneId then
                        currentDJZone = zoneId
                        SetNuiFocusKeepInput(false)
                        SetNuiFocus(true, true)
                        SendNUIMessage({ type = 'toggle', status = true, mode = 'dj' })
                        isUiOpen = true
                    end
                end,
                canInteract = function(entity)
                    return GetEntityModel(entity) == GetHashKey('prop_dj_deck_01')
                end
            },
            {
                name = 'dj_remove',
                icon = 'fa-solid fa-trash',
                label = 'Remove Prop',
                onSelect = function(data)
                    TriggerServerEvent('dj:removeSpecificProp', NetworkGetNetworkIdFromEntity(data.entity))
                end
            },
            {
                name = 'effect_manage',
                icon = 'fa-solid fa-layer-group',
                label = 'Gerenciar Efeitos',
                onSelect = function(data)
                    local entity = data.entity
                    local netId = NetworkGetNetworkIdFromEntity(entity)
                    local currentEffects = Entity(entity).state.effectConfigs or {}
                    
                    print("[DJ] Opening effect manager for NetId:", netId)
                    print("[DJ] Current effects:", json.encode(currentEffects))
                    
                    -- Open effect manager NUI
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        type = 'openEffectManager',
                        netId = netId,
                        effectConfigs = currentEffects
                    })
                end,
                canInteract = function(entity)
                    local model = GetEntityModel(entity)
                    
                    -- NÃO MOSTRAR para mesa DJ
                    if model == GetHashKey('prop_dj_deck_01') then
                        return false
                    end
                    
                    -- Mostrar apenas para props de efeito
                    return IsEffectModel(model)
                end
            },
            {
                name = 'speaker_link',
                icon = 'fa-solid fa-link',
                label = 'Link to DJ Table',
                onSelect = function(data)
                    ShowSpeakerLinkMenu(data.entity)
                end,
                canInteract = function(entity)
                    local model = GetEntityModel(entity)
                    return IsSpeakerModel(model) and not Entity(entity).state.zoneId
                end
            },
            {
                name = 'speaker_unlink',
                icon = 'fa-solid fa-unlink',
                label = 'Unlink Speaker',
                onSelect = function(data)
                    TriggerServerEvent('dj:unlinkSpeaker', NetworkGetNetworkIdFromEntity(data.entity))
                end,
                canInteract = function(entity)
                    local model = GetEntityModel(entity)
                    return IsSpeakerModel(model) and Entity(entity).state.zoneId ~= nil
                end
            },
            {
                name = 'effect_link',
                icon = 'fa-solid fa-link',
                label = 'Link Effect to DJ Table',
                onSelect = function(data)
                    ShowEffectLinkMenu(data.entity)
                end,
                canInteract = function(entity)
                    local model = GetEntityModel(entity)
                    return IsEffectModel(model) and not Entity(entity).state.zoneId
                end
            },
            {
                name = 'effect_unlink',
                icon = 'fa-solid fa-unlink',
                label = 'Unlink Effect',
                onSelect = function(data)
                    TriggerServerEvent('dj:unlinkEffect', NetworkGetNetworkIdFromEntity(data.entity))
                end,
                canInteract = function(entity)
                    local model = GetEntityModel(entity)
                    return IsEffectModel(model) and Entity(entity).state.zoneId ~= nil
                end
            }
        })
    -- Support for qb-target
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetModel(models, {
            options = {
                {
                    icon = 'fas fa-music',
                    label = 'Open DJ Decks',
                    action = function(entity)
                        local zoneId = Entity(entity).state.zoneId
                        
                        if zoneId then
                            currentDJZone = zoneId
                            SetNuiFocusKeepInput(false)
                            SetNuiFocus(true, true)
                            SendNUIMessage({ type = 'toggle', status = true, mode = 'dj' })
                            isUiOpen = true
                        end
                    end,
                    canInteract = function(entity)
                        return GetEntityModel(entity) == GetHashKey('prop_dj_deck_01')
                    end
                },
                {
                    icon = 'fas fa-trash',
                    label = 'Remove Prop',
                    action = function(entity)
                        TriggerServerEvent('dj:removeSpecificProp', NetworkGetNetworkIdFromEntity(entity))
                    end
                },
                {
                    icon = 'fas fa-sliders',
                    label = 'Reconfigure Effect',
                    action = function(entity)
                        local netId = NetworkGetNetworkIdFromEntity(entity)
                        local currentConfig = Entity(entity).state.effectConfig
                        
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            type = 'openEffectReconfigure',
                            netId = netId,
                            currentConfig = currentConfig
                        })
                    end,
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        return IsEffectModel(model) and Entity(entity).state.effectConfig
                    end
                },
                {
                    icon = 'fas fa-link',
                    label = 'Link to DJ Table',
                    action = function(entity)
                        ShowSpeakerLinkMenu(entity)
                    end,
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        return IsSpeakerModel(model) and not Entity(entity).state.zoneId
                    end
                },
                {
                    icon = 'fas fa-unlink',
                    label = 'Unlink Speaker',
                    action = function(entity)
                        TriggerServerEvent('dj:unlinkSpeaker', NetworkGetNetworkIdFromEntity(entity))
                    end,
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        return IsSpeakerModel(model) and Entity(entity).state.zoneId ~= nil
                    end
                },
                {
                    icon = 'fas fa-link',
                    label = 'Link Effect to DJ Table',
                    action = function(entity)
                        ShowEffectLinkMenu(entity)
                    end,
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        return IsEffectModel(model) and not Entity(entity).state.zoneId
                    end
                },
                {
                    icon = 'fas fa-unlink',
                    label = 'Unlink Effect',
                    action = function(entity)
                        TriggerServerEvent('dj:unlinkEffect', NetworkGetNetworkIdFromEntity(entity))
                    end,
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        return IsEffectModel(model) and Entity(entity).state.zoneId ~= nil
                    end
                }
            },
            distance = 2.5
        })
    else
        -- Fallback: Custom Raycast Interaction
        Citizen.CreateThread(function()
            while true do
                local sleep = 1000
                if not isUiOpen and not placementMode then
                    local hit, hitCoords, entityHit = RayCastGamePlayCamera(3.0)
                    if hit and entityHit ~= 0 then
                        local model = GetEntityModel(entityHit)
                        for _, mName in ipairs(models) do
                            if model == GetHashKey(mName) then
                                sleep = 5
                                local coords = GetEntityCoords(entityHit)
                                DrawMarker(2, coords.x, coords.y, coords.z + 1.2, 0,0,0, 0,0,0, 0.3,0.3,0.3, 255,255,255,200, true, true, 2, false, false, false, false)
                                
                                if model == GetHashKey('prop_dj_deck_01') then
                                    BeginTextCommandDisplayHelp("STRING")
                                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to Open DJ Decks\nPress ~INPUT_DETONATE~ to Remove")
                                    EndTextCommandDisplayHelp(0, false, true, -1)
                                    
                                    if IsControlJustPressed(0, 38) then -- E
                                        local zoneId = Entity(entityHit).state.zoneId
                                        if zoneId then
                                            currentDJZone = zoneId
                                            SetNuiFocusKeepInput(false)
                                            SetNuiFocus(true, true)
                                            SendNUIMessage({ type = 'toggle', status = true, mode = 'dj' })
                                            isUiOpen = true
                                        end
                                    end
                                elseif IsSpeakerModel(model) then
                                    local isLinked = Entity(entityHit).state.zoneId ~= nil
                                    
                                    if isLinked then
                                        BeginTextCommandDisplayHelp("STRING")
                                        AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to Unlink Speaker\nPress ~INPUT_DETONATE~ to Remove")
                                        EndTextCommandDisplayHelp(0, false, true, -1)
                                        
                                        if IsControlJustPressed(0, 38) then -- E
                                            TriggerServerEvent('dj:unlinkSpeaker', NetworkGetNetworkIdFromEntity(entityHit))
                                        end
                                    else
                                        BeginTextCommandDisplayHelp("STRING")
                                        AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to Link to DJ Table\nPress ~INPUT_DETONATE~ to Remove")
                                        EndTextCommandDisplayHelp(0, false, true, -1)
                                        
                                        if IsControlJustPressed(0, 38) then -- E
                                            ShowSpeakerLinkMenu(entityHit)
                                        end
                                    end
                                else
                                    BeginTextCommandDisplayHelp("STRING")
                                    AddTextComponentSubstringPlayerName("Press ~INPUT_DETONATE~ to Remove Prop")
                                    EndTextCommandDisplayHelp(0, false, true, -1)
                                end
                                
                                if IsControlJustPressed(0, 47) then -- G
                                    TriggerServerEvent('dj:removeSpecificProp', NetworkGetNetworkIdFromEntity(entityHit))
                                end
                                break
                            end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end
end)

-- Events from Server (Keep existing)
-- ...


-- Handle State Bag Changes for Effects
AddStateBagChangeHandler('effect', nil, function(bagName, key, value, _unused, replicated)
    local netId = tonumber((bagName:gsub('entity:', '')))
    if not netId then return end
    
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end
    
    if value and value ~= 'none' then
        StartEffectLoop(entity, value)
    end
end)

function StartEffectLoop(entity, effectName)
    Citizen.CreateThread(function()
        local dict, particle
        if effectName == "smoke" then
            dict = "core"
            particle = "exp_grd_grenade_smoke"
        elseif effectName == "fire" then
            dict = "scr_trevor3"
            particle = "scr_trev3_trailer_plume_flame"
        elseif effectName == "lights" then
            -- Custom light logic? Or particle?
            -- Let's use a particle for now or just skip loop
        end
        
        if dict then
            RequestNamedPtfxAsset(dict)
            while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
        end
        
        while DoesEntityExist(entity) and Entity(entity).state.effect == effectName do
            local coords = GetEntityCoords(entity)
            
            if effectName == "lights" then
                -- Strobe light effect
                DrawLightWithRange(coords.x, coords.y, coords.z + 1.0, 255, 255, 255, 5.0, 10.0)
                Wait(100)
                DrawLightWithRange(coords.x, coords.y, coords.z + 1.0, 0, 0, 0, 5.0, 10.0)
                Wait(100)
            else
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
                Wait(2000) -- Repeat every 2 seconds
            end
        end
    end)
end

-- Visual Link Lines Thread
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        
        -- Draw lines for each zone
        for zoneId, zone in pairs(audioZones) do
            if DoesEntityExist(zone.djTable) then
                local djCoords = GetEntityCoords(zone.djTable)
                local djDist = #(playerCoords - djCoords)
                
                -- Only draw if player is within 50m of DJ table
                if djDist <= 50.0 then
                    -- Draw lines from DJ table to each speaker
                    for i, speaker in ipairs(zone.speakers) do
                        if DoesEntityExist(speaker) then
                            local speakerCoords = GetEntityCoords(speaker)
                            
                            -- Animate the line color (pulsing effect)
                            local pulse = math.abs(math.sin(GetGameTimer() / 500.0))
                            local r = math.floor(0 + (100 * pulse))
                            local g = math.floor(200 + (55 * pulse))
                            local b = math.floor(255)
                            local a = 150
                            
                            -- Draw the line
                            DrawLine(
                                djCoords.x, djCoords.y, djCoords.z + 0.5,
                                speakerCoords.x, speakerCoords.y, speakerCoords.z + 0.5,
                                r, g, b, a
                            )
                            
                            -- Draw small markers at endpoints
                            DrawMarker(
                                28, -- Marker type (small sphere)
                                speakerCoords.x, speakerCoords.y, speakerCoords.z + 0.5,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                0.1, 0.1, 0.1,
                                r, g, b, a,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                    end
                    
                    -- Draw marker on DJ table
                    DrawMarker(
                        28,
                        djCoords.x, djCoords.y, djCoords.z + 0.5,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.15, 0.15, 0.15,
                        0, 255, 100, 200,
                        false, false, 2, false, nil, nil, false
                    )
                end
            end
        end
    end
end)

-- 3D Audio Distance Loop (Multi-Zone)
Citizen.CreateThread(function()
    while true do
        Wait(200)
        
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        -- Calculate volume for each zone independently
        for zoneId, zone in pairs(audioZones) do
            local minDist = nil
            
            -- Find closest speaker in this zone
            for _, speaker in ipairs(zone.speakers) do
                if DoesEntityExist(speaker) then
                    local speakerCoords = GetEntityCoords(speaker)
                    local dist = #(coords - speakerCoords)
                    if not minDist or dist < minDist then
                        minDist = dist
                    end
                end
            end
            
            -- If no speakers in zone, use DJ table position
            if not minDist and DoesEntityExist(zone.djTable) then
                local djCoords = GetEntityCoords(zone.djTable)
                minDist = #(coords - djCoords)
            end
            
            -- Calculate and send volume for this zone
            if minDist then
                local maxDist = 150.0
                local vol = 0.0
                
                if minDist <= maxDist then
                    vol = 1.0 - (minDist / maxDist)
                    if vol < 0 then vol = 0 end
                end
                
                SendNUIMessage({
                    type = 'updateZoneVolume',
                    zoneId = zoneId,
                    volume = vol
                })
            end
        end
    end
end)

-- Thread to keep props loaded and prevent despawn
Citizen.CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        for zoneId, zone in pairs(audioZones) do
            -- Keep DJ table loaded
            if zone.djTable and DoesEntityExist(zone.djTable) then
                SetEntityAsMissionEntity(zone.djTable, true, true)
            end
            
            -- Keep speakers loaded
            for _, speaker in ipairs(zone.speakers) do
                if DoesEntityExist(speaker) then
                    SetEntityAsMissionEntity(speaker, true, true)
                end
            end
        end
    end
end)

TriggerServerEvent('dj:requestSync')


-- Handle State Bag Changes for Effect Configuration (MULTIPLE EFFECTS SUPPORT)
AddStateBagChangeHandler('effectConfigs', nil, function(bagName, key, value, _unused, replicated)
    print("[DJ Effect] State bag changed:", bagName, key)
    print("[DJ Effect] Value:", json.encode(value))
    
    local netId = tonumber((bagName:gsub('entity:', '')))
    if not netId then 
        print("[DJ Effect] ERROR: Could not extract netId from bagName")
        return 
    end
    
    print("[DJ Effect] NetId:", netId)
    
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then 
        print("[DJ Effect] ERROR: Entity does not exist")
        return 
    end
    
    print("[DJ Effect] Entity exists:", entity)
    
    -- Stop all existing effects for this entity
    StopAllEffectsForEntity(entity)
    
    -- Start all configured effects
    if value and type(value) == 'table' then
        for effectId, config in pairs(value) do
            if config.type and config.type ~= 'none' then
                print(string.format("[DJ Effect] ✓ Starting effect %s: %s", effectId, config.type))
                StartConfiguredEffect(entity, effectId, config)
            end
        end
    else
        print("[DJ Effect] No effects configured")
    end
end)

-- BACKWARD COMPATIBILITY: Handle old effectConfig (singular) for props spawned before update
AddStateBagChangeHandler('effectConfig', nil, function(bagName, key, value, _unused, replicated)
    print("[DJ Effect] OLD State bag changed:", bagName, key)
    
    local netId = tonumber((bagName:gsub('entity:', '')))
    if not netId then return end
    
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end
    
    -- Convert old format to new format
    if value and value.type and value.type ~= 'none' then
        print("[DJ Effect] Converting old effectConfig to new effectConfigs format")
        
        -- Stop old effects
        StopAllEffectsForEntity(entity)
        
        -- Start with new format
        local effectId = "effect1"
        StartConfiguredEffect(entity, effectId, value)
    end
end)

-- Stop all effects for an entity
function StopAllEffectsForEntity(entity)
    if activeEffects[entity] then
        print(string.format("[DJ Effect] Stopping all effects for entity %d", entity))
        activeEffects[entity] = nil
    end
end

-- Start Configured Effect (with effect ID for multiple effects support)
function StartConfiguredEffect(entity, effectId, config)
    print("[DJ Effect] StartConfiguredEffect called")
    print("[DJ Effect] Effect ID:", effectId)
    print("[DJ Effect] Config type:", config.type)
    
    -- Initialize activeEffects for this entity if needed
    if not activeEffects[entity] then
        activeEffects[entity] = { effects = {} }
    end
    
    -- Store effect config
    activeEffects[entity].effects[effectId] = { config = config }
    
    if config.type == 'lights' then
        print("[DJ Effect] Starting STAGE LIGHTS effect")
        StartStageLightsEffect(entity, effectId, config.lights or {})
    elseif config.type == 'lasers' then
        print("[DJ Effect] Starting LASER SHOW effect")
        StartLaserShowEffect(entity, effectId, config.lasers or {})
    elseif config.type == 'smoke' then
        print("[DJ Effect] Starting SMOKE MACHINE effect")
        StartSmokeEffect(entity, effectId, config.smoke or {})
    elseif config.type == 'confetti' then
        print("[DJ Effect] Starting CONFETTI effect")
        StartConfettiEffect(entity, effectId, config.confetti or {})
    elseif config.type == 'bubbles' then
        print("[DJ Effect] Starting BUBBLES effect")
        StartBubblesEffect(entity, effectId, config.bubbles or {})
    elseif config.type == 'pyro' then
        print("[DJ Effect] Starting PYROTECHNICS effect")
        StartPyroEffect(entity, effectId, config.pyro or {})
    elseif config.type == 'co2' then
        print("[DJ Effect] Starting CO2 JETS effect")
        StartCO2Effect(entity, effectId, config.co2 or {})
    elseif config.type == 'uv' then
        print("[DJ Effect] Starting UV LIGHTS effect")
        StartUVEffect(entity, effectId, config.uv or {})
    else
        print("[DJ Effect] Unknown effect type:", config.type)
    end
end

-- Stage Lights Effect System (Professional Nightclub Lights)
-- REESCRITO COMPLETAMENTE - Efeitos volumétricos realistas como na imagem de referência
function StartStageLightsEffect(entity, effectId, lightConfig)
    print("[DJ Light] ========================================")
    print("[DJ Light] Starting VOLUMETRIC STAGE LIGHTS V2")
    print("[DJ Light] Effect ID:", effectId)
    print("[DJ Light] ========================================")
    
    Citizen.CreateThread(function()
        local r, g, b = HexToRGB(lightConfig.color or "#00ffff")
        local mode = lightConfig.mode or 'movinghead'
        local speed = lightConfig.speed or 1.0
        local intensity = lightConfig.intensity or 5.0
        local syncWithMusic = lightConfig.syncWithMusic or false
        
        print(string.format("[DJ Light] Config - Mode: %s, Color: RGB(%d,%d,%d), Intensity: %.1f, Sync: %s", 
            mode, r, g, b, intensity, tostring(syncWithMusic)))
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local time = GetGameTimer() / 1000.0
                local coords = GetEntityCoords(entity)
                local currentR, currentG, currentB = r, g, b
                local currentIntensity = intensity * 8.0
                
                -- Music sync boost - MELHORADO para ser mais perceptível
                if syncWithMusic and musicBeat.isPlaying then
                    local onBeat = IsOnBeat()
                    local beatPhase = GetBeatPhase()
                    
                    if onBeat then
                        -- Boost muito maior no beat (3x ao invés de 1.8x)
                        currentIntensity = currentIntensity * 3.0
                        
                        -- Adiciona pulsação baseada na fase do beat
                        local pulseFactor = 1.0 + (1.0 - beatPhase) * 0.5
                        currentIntensity = currentIntensity * pulseFactor
                        
                        -- Debug log every 30 frames
                        if frameCount % 30 == 0 then
                            print(string.format("[DJ Light] 🎵 ON BEAT! Intensity: %.1f -> %.1f (Phase: %.2f)", 
                                intensity * 8.0, currentIntensity, beatPhase))
                        end
                    else
                        -- Fade out suave entre beats
                        local fadeFactor = 0.5 + (beatPhase * 0.5)
                        currentIntensity = currentIntensity * fadeFactor
                    end
                end
                
                -- ============================================
                -- MOVING HEAD - ULTRA REALISTA COM VOLUMETRIA
                -- ============================================
                if mode == 'movinghead' then
                    local numBeams = 6
                    local beamHeight = 6.0
                    local beamDistance = 15.0
                    
                    -- NEBLINA VOLUMÉTRICA DENSA (como na imagem)
                    for layer = 1, 3 do
                        DrawMarker(
                            28,  -- Cilindro volumétrico
                            coords.x, coords.y, coords.z + (layer * 2),
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            20.0, 20.0, 4.0,
                            currentR, currentG, currentB, 15 + (layer * 5),
                            false, false, 2, false, nil, nil, false
                        )
                    end
                    
                    for i = 1, numBeams do
                        local angle = (time * 25 * speed + (i * (360 / numBeams))) % 360
                        local rad = math.rad(angle)
                        local tilt = math.sin(time * 0.6 + i) * 0.2
                        
                        -- Direção do beam
                        local dirX = math.cos(rad) * 0.6
                        local dirY = math.sin(rad) * 0.6
                        local dirZ = -0.85 + tilt
                        
                        -- Origem (acima do prop)
                        local originX = coords.x
                        local originY = coords.y
                        local originZ = coords.z + beamHeight
                        
                        -- Fim (no chão)
                        local endX = originX + dirX * beamDistance
                        local endY = originY + dirY * beamDistance
                        local endZ = coords.z - 0.5
                        
                        -- SPOTLIGHT PRINCIPAL (cone largo)
                        DrawSpotLight(
                            originX, originY, originZ,
                            dirX, dirY, dirZ,
                            currentR, currentG, currentB,
                            beamDistance * 2.5,
                            currentIntensity * 20,  -- MUITO MAIS INTENSO
                            0.0, 12.0, 45.0  -- Cone bem largo
                        )
                        
                        -- SPOTLIGHT SECUNDÁRIO (mais focado)
                        DrawSpotLight(
                            originX, originY, originZ,
                            dirX, dirY, dirZ,
                            currentR, currentG, currentB,
                            beamDistance * 1.5,
                            currentIntensity * 15,
                            0.0, 8.0, 30.0
                        )
                        
                        -- MÚLTIPLAS LINHAS PARA BEAM GROSSO
                        for lineOffset = -0.3, 0.3, 0.15 do
                            local perpX = -math.sin(rad) * lineOffset
                            local perpY = math.cos(rad) * lineOffset
                            
                            DrawLine(
                                originX + perpX, originY + perpY, originZ,
                                endX + perpX, endY + perpY, endZ,
                                currentR, currentG, currentB, 200
                            )
                        end
                        
                        -- LUZES AO LONGO DO BEAM (efeito volumétrico)
                        for step = 0, 1, 0.2 do
                            local stepX = originX + (endX - originX) * step
                            local stepY = originY + (endY - originY) * step
                            local stepZ = originZ + (endZ - originZ) * step
                            
                            DrawLightWithRange(
                                stepX, stepY, stepZ,
                                currentR, currentG, currentB,
                                4.0 + (step * 3),
                                currentIntensity * (3 - step * 2)
                            )
                        end
                        
                        -- LUZ NA ORIGEM (fonte do beam) - ULTRA BRILHANTE
                        DrawLightWithRange(originX, originY, originZ, currentR, currentG, currentB, 8.0, currentIntensity * 8)
                        DrawLightWithRange(originX, originY, originZ + 0.5, currentR, currentG, currentB, 6.0, currentIntensity * 6)
                        
                        -- LUZ NO CHÃO (onde atinge) - MUITO BRILHANTE
                        DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 12.0, currentIntensity * 10)
                        DrawLightWithRange(endX, endY, endZ + 0.5, currentR, currentG, currentB, 10.0, currentIntensity * 8)
                        
                        -- MARKER NO CHÃO (glow circular grande)
                        DrawMarker(
                            25,
                            endX, endY, coords.z - 0.98,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            10.0, 10.0, 0.1,
                            currentR, currentG, currentB, 240,
                            false, false, 2, false, nil, nil, false
                        )
                        
                        -- MARKER VOLUMÉTRICO NO MEIO DO BEAM
                        local midX = originX + dirX * (beamDistance * 0.5)
                        local midY = originY + dirY * (beamDistance * 0.5)
                        local midZ = originZ + dirZ * (beamDistance * 0.5)
                        
                        DrawMarker(
                            28,
                            midX, midY, midZ,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            3.0, 3.0, 6.0,
                            currentR, currentG, currentB, 80,
                            false, false, 2, false, nil, nil, false
                        )
                    end
                    
                    -- NEBLINA NO CHÃO (ground fog)
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + 0.3,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        25.0, 25.0, 1.0,
                        currentR, currentG, currentB, 40,
                        false, false, 2, false, nil, nil, false
                    )
                    
                elseif mode == 'strobe' then
                    local strobe
                    if syncWithMusic and musicBeat.isPlaying then
                        strobe = IsOnBeat() and 1 or 0
                    else
                        local strobeSpeed = 40 / speed
                        strobe = math.floor(GetGameTimer() / strobeSpeed) % 2
                    end
                    
                    if strobe == 1 then
                        local strobeIntensity = intensity * 20
                        for i = 1, 20 do
                            local angle = i * 18
                            local rad = math.rad(angle)
                            local dist = 6.0
                            local lx = coords.x + math.cos(rad) * dist
                            local ly = coords.y + math.sin(rad) * dist
                            DrawLightWithRange(lx, ly, coords.z + 2.0, 255, 255, 255, 20.0, strobeIntensity * 3)
                        end
                        for h = 1, 5 do
                            DrawLightWithRange(coords.x, coords.y, coords.z + h, 255, 255, 255, 25.0, strobeIntensity * 4)
                        end
                        DrawMarker(25, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 40.0, 40.0, 0.1, 255, 255, 255, 255, false, false, 2, false, nil, nil, false)
                    end
                    
                elseif mode == 'wash' then
                    for i = 1, 8 do
                        local angle = (i * 45) + (time * 15 * speed)
                        local rad = math.rad(angle)
                        DrawSpotLight(coords.x, coords.y, coords.z + 3.0, math.cos(rad), math.sin(rad), -0.4, currentR, currentG, currentB, 20.0, currentIntensity * 4, 0.0, 15.0, 70.0)
                    end
                    DrawMarker(25, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 25.0, 25.0, 0.1, currentR, currentG, currentB, 150, false, false, 2, false, nil, nil, false)
                    
                elseif mode == 'disco' then
                    for i = 1, 12 do
                        local angle = (time * 60 * speed + (i * 30)) % 360
                        local rad = math.rad(angle)
                        local hue = ((time * 120) + (i * 30)) % 360
                        local dr, dg, db = HSVToRGB(hue, 1, 1)
                        local dist = 10.0
                        local endX = coords.x + math.cos(rad) * dist
                        local endY = coords.y + math.sin(rad) * dist
                        DrawSpotLight(coords.x, coords.y, coords.z + 3.0, math.cos(rad), math.sin(rad), -0.3, dr, dg, db, 15.0, currentIntensity * 3, 0.0, 6.0, 30.0)
                        DrawLightWithRange(endX, endY, coords.z - 0.5, dr, dg, db, 5.0, currentIntensity * 2)
                    end
                    
                elseif mode == 'scanner' then
                    local scanAngle = (time * 120 * speed) % 360
                    local scanRad = math.rad(scanAngle)
                    local scanDist = 18.0
                    local endX = coords.x + math.cos(scanRad) * scanDist
                    local endY = coords.y + math.sin(scanRad) * scanDist
                    DrawSpotLight(coords.x, coords.y, coords.z + 3.0, math.cos(scanRad), math.sin(scanRad), -0.2, currentR, currentG, currentB, scanDist * 2, currentIntensity * 5, 0.0, 10.0, 20.0)
                    DrawLine(coords.x, coords.y, coords.z + 3.0, endX, endY, coords.z - 0.5, currentR, currentG, currentB, 255)
                    DrawLightWithRange(endX, endY, coords.z - 0.5, currentR, currentG, currentB, 8.0, currentIntensity * 4)
                    
                elseif mode == 'chase' then
                    local chaseIndex = math.floor(time * 3 * speed) % 8
                    for i = 0, 7 do
                        if i == chaseIndex or i == (chaseIndex - 1) % 8 then
                            local angle = i * 45
                            local rad = math.rad(angle)
                            local dist = 6.0
                            local lx = coords.x + math.cos(rad) * dist
                            local ly = coords.y + math.sin(rad) * dist
                            DrawLightWithRange(lx, ly, coords.z + 2.0, currentR, currentG, currentB, 12.0, currentIntensity * 5)
                            DrawSpotLight(coords.x, coords.y, coords.z + 3.0, math.cos(rad), math.sin(rad), -0.3, currentR, currentG, currentB, 12.0, currentIntensity * 4, 0.0, 8.0, 35.0)
                        end
                    end
                    
                elseif mode == 'rainbow' then
                    local hue = (time * 60 * speed) % 360
                    currentR, currentG, currentB = HSVToRGB(hue, 1, 1)
                    for i = 1, 6 do
                        local angle = i * 60
                        local rad = math.rad(angle)
                        local beamHue = (hue + (i * 60)) % 360
                        local br, bg, bb = HSVToRGB(beamHue, 1, 1)
                        DrawSpotLight(coords.x, coords.y, coords.z + 4.0, math.cos(rad) * 0.4, math.sin(rad) * 0.4, -0.8, br, bg, bb, 15.0, currentIntensity * 4, 0.0, 8.0, 30.0)
                    end
                    DrawLightWithRange(coords.x, coords.y, coords.z + 3.0, currentR, currentG, currentB, 15.0, currentIntensity * 3)
                    
                elseif mode == 'pulse' then
                    local pulse = (math.sin(time * 3 * speed) + 1) / 2
                    local pulseIntensity = currentIntensity * pulse
                    for h = 1, 4 do
                        DrawLightWithRange(coords.x, coords.y, coords.z + h, currentR, currentG, currentB, 15.0, pulseIntensity * 2)
                    end
                    DrawMarker(25, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0 * pulse, 20.0 * pulse, 0.1, currentR, currentG, currentB, math.floor(200 * pulse), false, false, 2, false, nil, nil, false)
                end
                
            end
            
            Wait(IsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ Light] Effect stopped")
    end)
end

-- Smoke Effect System (ULTRA REALISTA - Neblina de Balada)
function StartSmokeEffect(entity, effectId, smokeConfig)
    print("[DJ Smoke] Starting ULTRA REALISTIC smoke effect")
    print("[DJ Smoke] Effect ID:", effectId)
    
    Citizen.CreateThread(function()
        local mode = smokeConfig.mode or 'continuous'
        local density = smokeConfig.density or 1.0
        local height = smokeConfig.height or 2.0
        local syncWithMusic = smokeConfig.syncWithMusic or false
        
        print(string.format("[DJ Smoke] Sync with music: %s", tostring(syncWithMusic)))
        
        -- Múltiplos tipos de partículas para realismo
        local smokeAssets = {
            {dict = "core", particle = "exp_grd_bzgas_smoke"},
            {dict = "core", particle = "exp_grd_grenade_smoke"},
            {dict = "scr_agencyheistb", particle = "scr_env_agency3b_smoke"}
        }
        
        -- Carregar assets
        for _, asset in ipairs(smokeAssets) do
            RequestNamedPtfxAsset(asset.dict)
            while not HasNamedPtfxAssetLoaded(asset.dict) do Wait(10) end
        end
        
        print("[DJ Smoke] ✓ Assets carregados")
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if ShouldShowEffect(entity) then
                local coords = GetEntityCoords(entity)
                local currentDensity = density
                local burstNow = false
            
            -- Sincronização com música
            if syncWithMusic and musicBeat.isPlaying then
                local onBeat = IsOnBeat()
                
                if frameCount == 1 then
                    print("[DJ Smoke] ✓ Sincronização ativa")
                end
                
                if onBeat then
                    currentDensity = density * 3  -- TRIPLICADO na batida
                    burstNow = true
                    if frameCount % 60 == 0 then
                        print("[DJ Smoke] ♪ BATIDA! Explosão de fumaça")
                    end
                end
            end
            
            if mode == 'continuous' then
                -- NEBLINA DENSA CONTÍNUA (como balada real)
                for i = 1, math.floor(currentDensity * 12) do  -- MUITO MAIS DENSO
                    local offsetX = math.random(-150, 150) / 100  -- Área MAIOR
                    local offsetY = math.random(-150, 150) / 100
                    local offsetZ = math.random(0, 50) / 100
                    
                    UseParticleFxAssetNextCall("core")
                    StartParticleFxNonLoopedAtCoord(
                        "exp_grd_bzgas_smoke",
                        coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ,
                        0.0, 0.0, 0.0,
                        currentDensity * 5.0, false, false, false  -- MUITO MAIS INTENSO
                    )
                end
                
                -- Camada intermediária
                for i = 1, math.floor(currentDensity * 6) do
                    local offsetX = math.random(-100, 100) / 100
                    local offsetY = math.random(-100, 100) / 100
                    
                    UseParticleFxAssetNextCall("core")
                    StartParticleFxNonLoopedAtCoord(
                        "exp_grd_grenade_smoke",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 0.5,
                        0.0, 0.0, 0.0,
                        currentDensity * 3.5, false, false, false
                    )
                end
                
                -- Camada superior (névoa alta)
                for i = 1, math.floor(currentDensity * 3) do
                    local offsetX = math.random(-80, 80) / 100
                    local offsetY = math.random(-80, 80) / 100
                    
                    UseParticleFxAssetNextCall("scr_agencyheistb")
                    StartParticleFxNonLoopedAtCoord(
                        "scr_env_agency3b_smoke",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 1.5,
                        0.0, 0.0, 0.0,
                        currentDensity * 2.5, false, false, false
                    )
                end
                
                -- Neblina volumétrica no chão (NOVO)
                for layer = 1, 3 do
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + (layer * 0.3),
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        8.0 + (layer * 2), 8.0 + (layer * 2), 1.0,
                        200, 200, 220, 40 + (layer * 10),
                        false, false, 2, false, nil, nil, false
                    )
                end
                
                Wait(800)  -- Mais rápido para manter densidade
                
            elseif mode == 'burst' then
                -- EXPLOSÃO DE FUMAÇA (sincronizada com batida)
                if burstNow or not syncWithMusic then
                    -- Explosão radial massiva
                    for i = 1, 16 do  -- DOBRADO
                        local angle = (i / 16) * 360
                        local rad = math.rad(angle)
                        local offsetX = math.cos(rad) * 1.5
                        local offsetY = math.sin(rad) * 1.5
                        
                        UseParticleFxAssetNextCall("core")
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_grenade_smoke",
                            coords.x + offsetX, coords.y + offsetY, coords.z + height,
                            0.0, 0.0, 0.0,
                            currentDensity * 5, false, false, false  -- MUITO MAIS INTENSO
                        )
                    end
                    
                    -- Explosão central
                    for i = 1, 5 do
                        UseParticleFxAssetNextCall("core")
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_bzgas_smoke",
                            coords.x, coords.y, coords.z + 0.5,
                            0.0, 0.0, 0.0,
                            currentDensity * 6, false, false, false
                        )
                    end
                    
                    if not syncWithMusic then
                        Wait(4000)
                    else
                        Wait(100)
                    end
                else
                    Wait(100)
                end
                
            elseif mode == 'ground' then
                -- NEBLINA RASTEIRA (fog de balada)
                for i = 1, math.floor(currentDensity * 10) do  -- MUITO MAIS DENSO
                    local offsetX = math.random(-200, 200) / 100  -- Área MAIOR
                    local offsetY = math.random(-200, 200) / 100
                    
                    UseParticleFxAssetNextCall("core")
                    StartParticleFxNonLoopedAtCoord(
                        "exp_grd_bzgas_smoke",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 0.05,
                        0.0, 0.0, 0.0,
                        currentDensity * 3.0, false, false, false
                    )
                end
                
                -- Névoa volumétrica em camadas
                for layer = 1, 5 do
                    local mistAlpha = syncWithMusic and IsOnBeat() and (60 + layer * 15) or (30 + layer * 10)
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + (layer * 0.2),
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        12.0 + (layer * 3), 12.0 + (layer * 3), 0.8,
                        200, 200, 220, mistAlpha,
                        false, false, 2, false, nil, nil, false
                    )
                end
                
                Wait(1500)
            end
            end
            
            Wait(ShouldShowEffect(entity) and 0 or 500)
        end
        
        print("[DJ Smoke] Efeito parado")
    end)
end

-- Firework Effect System (Enhanced & Immersive)
function StartFireworkEffect(entity, effectId, fireworkConfig)
    print("[DJ Firework] Starting ENHANCED firework effect thread")
    
    Citizen.CreateThread(function()
        local fwType = fireworkConfig.type or 'fountain'
        local frequency = (fireworkConfig.frequency or 2.0) * 1000
        local size = fireworkConfig.size or 1.0
        local r, g, b = HexToRGB(fireworkConfig.color or "#ff0000")
        
        local dict = "scr_indep_fireworks"
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
        
        local dict2 = "scr_rcbarry2"
        RequestNamedPtfxAsset(dict2)
        while not HasNamedPtfxAssetLoaded(dict2) do Wait(10) end
        
        print("[DJ Firework] ✓ Firework assets loaded")
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            local coords = GetEntityCoords(entity)
            
            if fwType == 'fountain' then
                -- Fountain effect - continuous sparks
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(
                    "scr_indep_firework_fountain",
                    coords.x, coords.y, coords.z + 0.2,
                    0.0, 0.0, 0.0,
                    size * 1.5, false, false, false
                )
                
                -- Add light flash
                DrawLightWithRange(coords.x, coords.y, coords.z + 1.0, r, g, b, 8.0, 10.0)
                
            elseif fwType == 'rocket' then
                -- Rocket - shoots up then explodes
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(
                    "scr_indep_firework_starburst",
                    coords.x, coords.y, coords.z + 10.0,
                    0.0, 0.0, 0.0,
                    size * 2, false, false, false
                )
                
                -- Trail effect
                for i = 1, 10 do
                    DrawLightWithRange(
                        coords.x, coords.y, coords.z + i,
                        r, g, b, 3.0, 5.0
                    )
                end
                
            elseif fwType == 'sparkler' then
                -- Sparkler - continuous sparkles
                for i = 1, 3 do
                    local offsetX = math.random(-50, 50) / 100
                    local offsetY = math.random(-50, 50) / 100
                    
                    UseParticleFxAssetNextCall(dict2)
                    StartParticleFxNonLoopedAtCoord(
                        "scr_clown_appears",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 1.0,
                        0.0, 0.0, 0.0,
                        size, false, false, false
                    )
                end
                
            elseif fwType == 'roman' then
                -- Roman candle - shoots balls of fire
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(
                    "scr_indep_firework_trailburst",
                    coords.x, coords.y, coords.z + 0.5,
                    math.random(-20, 20), math.random(-20, 20), 45.0,
                    size * 1.5, false, false, false
                )
                
                -- Explosion light
                DrawLightWithRange(coords.x, coords.y, coords.z + 5.0, r, g, b, 12.0, 15.0)
            end
            
            Wait(frequency)
        end
        
        print("[DJ Firework] Effect stopped")
    end)
end

-- Laser Show Effect System (Party Lasers) - ENHANCED WITH BEAT SYNC
function StartLaserShowEffect(entity, effectId, laserConfig)
    print("[DJ Laser] Starting ENHANCED LASER SHOW effect")
    print("[DJ Laser] Effect ID:", effectId)
    
    Citizen.CreateThread(function()
        local r, g, b = HexToRGB(laserConfig.color or "#00ff00")
        local pattern = laserConfig.pattern or 'beams'
        local count = laserConfig.count or 4
        local speed = laserConfig.speed or 1.0
        local syncWithMusic = laserConfig.syncWithMusic or false
        
        print(string.format("[DJ Laser] Sync with music: %s", tostring(syncWithMusic)))
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local time = GetGameTimer() / (1000 / speed)
                
                local currentIntensity = 8.0
                local currentCount = count
                local currentR, currentG, currentB = r, g, b
            
            -- Music synchronization
            -- Music synchronization - MELHORADO
            if syncWithMusic and musicBeat.isPlaying then
                local onBeat = IsOnBeat()
                local beatPhase = GetBeatPhase()
                
                if frameCount == 1 then
                    print("[DJ Laser] ✓ Music sync ACTIVE")
                end
                
                -- Boost MUITO MAIOR no beat
                if onBeat then
                    currentIntensity = currentIntensity * 4.0  -- 4x ao invés de 2x
                    currentCount = math.min(count * 3, 16)  -- Mais lasers no beat
                    
                    -- Flash rápido no beat
                    local flashFactor = 1.0 + (1.0 - beatPhase) * 2.0
                    currentIntensity = currentIntensity * flashFactor
                    
                    if frameCount % 60 == 0 then
                        print(string.format("[DJ Laser] 🎵 ON BEAT! Intensity: %.1f, Count: %d", 
                            currentIntensity, currentCount))
                    end
                else
                    -- Fade out entre beats
                    currentIntensity = currentIntensity * (0.3 + beatPhase * 0.7)
                end
                
                -- Rotação mais rápida no beat
                if onBeat then
                    time = time * 2.0
                end
                
                -- Muda cor no beat para alguns padrões
                if (pattern == 'random' or pattern == 'rainbow') and onBeat then
                    local hue = (musicBeat.beat * 90) % 360
                    currentR, currentG, currentB = HSVToRGB(hue, 1, 1)
                end
            end
            
            if pattern == 'beams' then
                -- LASERS ROTATIVOS ULTRA REALISTAS (como balada profissional)
                for i = 1, currentCount do
                    local angle = (time * 30 + (i * (360 / currentCount))) % 360
                    local rad = math.rad(angle)
                    local distance = 50.0  -- MUITO MAIOR
                    local height = math.sin(time * 0.5 + i) * 7.0  -- Movimento MAIS amplo
                    local endX = coords.x + math.cos(rad) * distance
                    local endY = coords.y + math.sin(rad) * distance
                    local endZ = coords.z + 2.5 + height
                    
                    -- BEAM VOLUMÉTRICO GROSSO (5 linhas paralelas)
                    for j = 0, 4 do
                        local offset = (j - 2) * 0.12  -- Mais espaçamento
                        local offsetX = math.cos(rad + math.pi/2) * offset
                        local offsetY = math.sin(rad + math.pi/2) * offset
                        
                        DrawLine(
                            coords.x + offsetX, coords.y + offsetY, coords.z + 2.5,
                            endX + offsetX, endY + offsetY, endZ,
                            currentR, currentG, currentB, 255
                        )
                    end
                    
                    -- LUZES AO LONGO DO BEAM (efeito volumétrico intenso)
                    for step = 0, 1, 0.15 do
                        local stepX = coords.x + (endX - coords.x) * step
                        local stepY = coords.y + (endY - coords.y) * step
                        local stepZ = coords.z + 2.5 + (endZ - (coords.z + 2.5)) * step
                        
                        DrawLightWithRange(
                            stepX, stepY, stepZ,
                            currentR, currentG, currentB,
                            5.0 + (step * 4),
                            currentIntensity * (4 - step * 2)
                        )
                    end
                    
                    -- ENDPOINT GLOW MASSIVO
                    DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 10.0, currentIntensity * 3)
                    DrawLightWithRange(endX, endY, endZ + 0.5, currentR, currentG, currentB, 8.0, currentIntensity * 2)
                    
                    -- MARKER NO ENDPOINT (glow circular)
                    DrawMarker(
                        25,
                        endX, endY, endZ - 0.5,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        6.0, 6.0, 0.1,
                        currentR, currentG, currentB, 200,
                        false, false, 2, false, nil, nil, false
                    )
                    
                    -- ORIGIN GLOW ULTRA BRILHANTE
                    DrawLightWithRange(coords.x, coords.y, coords.z + 2.5, currentR, currentG, currentB, 8.0, currentIntensity * 2)
                    DrawLightWithRange(coords.x, coords.y, coords.z + 3.0, currentR, currentG, currentB, 6.0, currentIntensity * 1.5)
                    
                    -- MARKER VOLUMÉTRICO NA ORIGEM
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + 2.5,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        2.0, 2.0, 2.0,
                        currentR, currentG, currentB, 150,
                        false, false, 2, false, nil, nil, false
                    )
                end
                
            elseif pattern == 'grid' then
                -- Dynamic grid pattern
                local gridSize = 15.0
                local gridSpacing = 2.5
                
                -- Vertical lines
                for i = -3, 3 do
                    local offsetX = i * gridSpacing
                    DrawLine(
                        coords.x + offsetX, coords.y - gridSize, coords.z + 4.0,
                        coords.x + offsetX, coords.y + gridSize, coords.z + 4.0,
                        currentR, currentG, currentB, 220
                    )
                end
                
                -- Horizontal lines
                for i = -6, 6 do
                    local offsetY = i * gridSpacing
                    DrawLine(
                        coords.x - gridSize, coords.y + offsetY, coords.z + 4.0,
                        coords.x + gridSize, coords.y + offsetY, coords.z + 4.0,
                        currentR, currentG, currentB, 220
                    )
                end
                
                -- Grid lights at intersections
                for x = -3, 3 do
                    for y = -6, 6 do
                        if (x + y) % 2 == math.floor(time) % 2 then
                            DrawLightWithRange(
                                coords.x + x * gridSpacing,
                                coords.y + y * gridSpacing,
                                coords.z + 4.0,
                                currentR, currentG, currentB, 2.0, currentIntensity * 0.3
                            )
                        end
                    end
                end
                
            elseif pattern == 'spiral' then
                -- Enhanced spiral pattern
                for i = 1, currentCount do
                    local spiralAngle = (time * 50 + (i * 360 / currentCount)) % 360
                    local spiralRad = math.rad(spiralAngle)
                    local spiralDist = 8.0 + math.sin(time * 0.5 + i) * 4.0
                    local endX = coords.x + math.cos(spiralRad) * spiralDist
                    local endY = coords.y + math.sin(spiralRad) * spiralDist
                    local endZ = coords.z + 3.0 + math.sin(time + i) * 3.0
                    
                    DrawLine(coords.x, coords.y, coords.z + 2.5, endX, endY, endZ, currentR, currentG, currentB, 255)
                    DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 3.0, currentIntensity)
                end
                
            elseif pattern == 'random' then
                -- Random sweep with trails
                if frameCount % 3 == 0 then
                    for i = 1, currentCount do
                        local randAngle = math.random(0, 360)
                        local randRad = math.rad(randAngle)
                        local randDist = math.random(15, 25)
                        local endX = coords.x + math.cos(randRad) * randDist
                        local endY = coords.y + math.sin(randRad) * randDist
                        local endZ = coords.z + math.random(1, 5)
                        
                        DrawLine(coords.x, coords.y, coords.z + 2.5, endX, endY, endZ, currentR, currentG, currentB, 255)
                        DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 4.0, currentIntensity)
                    end
                end
            end
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ Laser] Effect stopped")
    end)
end

-- Confetti Effect System (Party Confetti) - ENHANCED WITH BEAT SYNC
function StartConfettiEffect(entity, effectId, confettiConfig)
    print("[DJ Confetti] Starting ENHANCED CONFETTI effect")
    
    Citizen.CreateThread(function()
        local style = confettiConfig.style or 'colorful'
        local intensity = confettiConfig.intensity or 1.0
        local mode = confettiConfig.mode or 'cannon'
        local frequency = (confettiConfig.frequency or 3.0) * 1000
        local syncWithMusic = confettiConfig.syncWithMusic or false
        
        print(string.format("[DJ Confetti] Sync with music: %s", tostring(syncWithMusic)))
        
        -- Load multiple particle assets
        local dict1 = "scr_rcbarry2"
        local dict2 = "scr_indep_fireworks"
        RequestNamedPtfxAsset(dict1)
        RequestNamedPtfxAsset(dict2)
        while not HasNamedPtfxAssetLoaded(dict1) or not HasNamedPtfxAssetLoaded(dict2) do Wait(10) end
        
        print("[DJ Confetti] ✓ Particle assets loaded")
        
        local frameCount = 0
        local lastBurst = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local currentTime = GetGameTimer()
                
                local currentIntensity = intensity
                local shouldBurst = false
            
            -- Music synchronization
            if syncWithMusic and musicBeat.isPlaying then
                local onBeat = IsOnBeat()
                
                if frameCount == 1 then
                    print("[DJ Confetti] ✓ Music sync ACTIVE")
                end
                
                -- Burst on beat
                if onBeat and (currentTime - lastBurst) > 400 then
                    currentIntensity = intensity * 1.5
                    shouldBurst = true
                    lastBurst = currentTime
                    if frameCount % 60 == 0 then
                        print("[DJ Confetti] ♪ ON BEAT! Confetti burst")
                    end
                end
            end
            
            if mode == 'cannon' then
                -- CANHÃO DE CONFETTI MASSIVO (como shows profissionais)
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > frequency) then
                    print("[DJ Confetti] 🎉 CANHÃO DISPARADO!")
                    lastBurst = currentTime
                    
                    -- EXPLOSÃO MASSIVA DE CONFETTI (TRIPLICADO)
                    for i = 1, math.floor(currentIntensity * 30) do
                        local angleOffset = math.random(0, 360)
                        UseParticleFxAssetNextCall(dict1)
                        StartParticleFxNonLoopedAtCoord(
                            "scr_clown_appears",
                            coords.x, coords.y, coords.z + 0.5,
                            0.0, 0.0, angleOffset,
                            currentIntensity * 6, false, false, false
                        )
                    end
                    
                    -- FOGOS DE ARTIFÍCIO COLORIDOS (DOBRADO)
                    for i = 1, 12 do
                        local offsetX = math.random(-50, 50) / 100
                        local offsetY = math.random(-50, 50) / 100
                        UseParticleFxAssetNextCall(dict2)
                        StartParticleFxNonLoopedAtCoord(
                            "scr_indep_firework_starburst",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 3.0,
                            0.0, 0.0, 0.0,
                            currentIntensity * 3, false, false, false
                        )
                    end
                    
                    -- EXPLOSÃO DE SPARKLES (NOVO)
                    for i = 1, 8 do
                        UseParticleFxAssetNextCall(dict2)
                        StartParticleFxNonLoopedAtCoord(
                            "scr_indep_firework_sparkle_spawn",
                            coords.x, coords.y, coords.z + 1.5,
                            0.0, 0.0, 0.0,
                            currentIntensity * 2, false, false, false
                        )
                    end
                    
                    -- FLASH DE LUZ MASSIVO (múltiplas camadas)
                    for h = 1, 4 do
                        DrawLightWithRange(coords.x, coords.y, coords.z + h, 255, 200, 100, 20.0, 40.0)
                    end
                    
                    -- GLOW NO CHÃO
                    DrawMarker(
                        25,
                        coords.x, coords.y, coords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        15.0, 15.0, 0.1,
                        255, 200, 100, 255,
                        false, false, 2, false, nil, nil, false
                    )
                end
                
                Wait(100)
                
            elseif mode == 'rain' then
                -- Confetti rain from above
                for i = 1, math.floor(currentIntensity * 8) do
                    local offsetX = math.random(-300, 300) / 100
                    local offsetY = math.random(-300, 300) / 100
                    
                    UseParticleFxAssetNextCall(dict1)
                    StartParticleFxNonLoopedAtCoord(
                        "scr_clown_appears",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 8.0,
                        0.0, 0.0, 0.0,
                        currentIntensity * 2, false, false, false
                    )
                end
                Wait(1500)
                
            elseif mode == 'burst' then
                -- 360 degree burst (sync with beat if enabled)
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > frequency) then
                    lastBurst = currentTime
                    
                    for angle = 0, 360, 25 do
                        local rad = math.rad(angle)
                        local offsetX = math.cos(rad) * 1.2
                        local offsetY = math.sin(rad) * 1.2
                        
                        UseParticleFxAssetNextCall(dict1)
                        StartParticleFxNonLoopedAtCoord(
                            "scr_clown_appears",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 1.0,
                            0.0, 0.0, angle,
                            currentIntensity * 3, false, false, false
                        )
                    end
                    
                    -- Center burst
                    UseParticleFxAssetNextCall(dict2)
                    StartParticleFxNonLoopedAtCoord(
                        "scr_indep_firework_fountain",
                        coords.x, coords.y, coords.z + 0.5,
                        0.0, 0.0, 0.0,
                        currentIntensity * 2, false, false, false
                    )
                end
                
                Wait(100)
            end
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 100 or 500)
        end
        
        print("[DJ Confetti] Effect stopped")
    end)
end

-- Bubbles Effect System (Party Bubbles) - ENHANCED & VISIBLE
function StartBubblesEffect(entity, effectId, bubbleConfig)
    print("[DJ Bubbles] Starting ENHANCED BUBBLES effect")
    
    Citizen.CreateThread(function()
        local size = bubbleConfig.size or 'medium'
        local amount = bubbleConfig.amount or 1.0
        local mode = bubbleConfig.mode or 'continuous'
        
        local sizeScale = size == 'small' and 0.5 or size == 'large' and 2.0 or size == 'mixed' and 1.2 or 1.0
        
        -- Load particle effects
        local dict = "core"
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
        
        local bubbleTimer = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                bubbleTimer = bubbleTimer + 1
            
            if mode == 'continuous' then
                -- MÁQUINA DE BOLHAS PROFISSIONAL (fluxo contínuo massivo)
                for i = 1, math.floor(amount * 20) do  -- MUITO MAIS BOLHAS
                    local offsetX = math.random(-200, 200) / 100  -- Área MAIOR
                    local offsetY = math.random(-200, 200) / 100
                    local height = 0.5 + (i * 0.3) + math.random(0, 100) / 100
                    local bubbleSize = size == 'mixed' and math.random(50, 180) / 100 or sizeScale * 1.5
                    
                    -- Bolha como esfera brilhante (MAIS VISÍVEL)
                    DrawMarker(
                        28,
                        coords.x + offsetX, coords.y + offsetY, coords.z + height,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        bubbleSize, bubbleSize, bubbleSize,
                        150, 220, 255, 180,  -- MAIS OPACO
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Luz na bolha (MAIS BRILHANTE)
                    DrawLightWithRange(
                        coords.x + offsetX, coords.y + offsetY, coords.z + height,
                        150, 220, 255, 3.0, 6.0
                    )
                    
                    -- Reflexo da bolha (NOVO)
                    if i % 3 == 0 then
                        DrawMarker(
                            28,
                            coords.x + offsetX, coords.y + offsetY, coords.z + height,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            bubbleSize * 0.6, bubbleSize * 0.6, bubbleSize * 0.6,
                            255, 255, 255, 100,
                            false, true, 2, false, nil, nil, false
                        )
                    end
                end
                
                -- Partículas de bolhas (MAIS FREQUENTE)
                if bubbleTimer % 15 == 0 then  -- DOBRADO
                    for i = 1, 5 do
                        local offsetX = math.random(-50, 50) / 100
                        local offsetY = math.random(-50, 50) / 100
                        
                        UseParticleFxAssetNextCall(dict)
                        StartParticleFxNonLoopedAtCoord(
                            "water_splash_ped_bubbles",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 0.5,
                            0.0, 0.0, 0.0,
                            amount * 4, false, false, false
                        )
                    end
                end
                
                -- Névoa de bolhas no chão (NOVO)
                DrawMarker(
                    28,
                    coords.x, coords.y, coords.z + 0.5,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    8.0, 8.0, 3.0,
                    150, 220, 255, 40,
                    false, false, 2, false, nil, nil, false
                )
                
                Wait(80)  -- Mais rápido
                
            elseif mode == 'burst' then
                -- Massive bubble burst
                for i = 1, math.floor(amount * 20) do
                    local angle = math.random(0, 360)
                    local rad = math.rad(angle)
                    local dist = math.random(100, 300) / 100
                    local offsetX = math.cos(rad) * dist
                    local offsetY = math.sin(rad) * dist
                    local height = math.random(50, 250) / 100
                    local bubbleSize = size == 'mixed' and math.random(40, 150) / 100 or sizeScale
                    
                    -- Draw bubble
                    DrawMarker(
                        28,
                        coords.x + offsetX, coords.y + offsetY, coords.z + height,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        bubbleSize, bubbleSize, bubbleSize,
                        150, 200, 255, 150,
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Light
                    DrawLightWithRange(
                        coords.x + offsetX, coords.y + offsetY, coords.z + height,
                        150, 200, 255, 3.0, 5.0
                    )
                end
                
                -- Particle burst
                for angle = 0, 360, 45 do
                    local rad = math.rad(angle)
                    local offsetX = math.cos(rad) * 0.5
                    local offsetY = math.sin(rad) * 0.5
                    
                    UseParticleFxAssetNextCall(dict)
                    StartParticleFxNonLoopedAtCoord(
                        "water_splash_ped_bubbles",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 1.0,
                        0.0, 0.0, 0.0,
                        amount * 3, false, false, false
                    )
                end
                
                Wait(2000)
            end
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 100 or 500)
        end
        
        print("[DJ Bubbles] Effect stopped")
    end)
end

-- Pyrotechnics Effect System (Flames, Fireworks, Sparklers)
function StartPyroEffect(entity, effectId, pyroConfig)
    print("[DJ Pyro] Starting PYROTECHNICS effect")
    
    Citizen.CreateThread(function()
        local r, g, b = HexToRGB(pyroConfig.color or "#ff4400")
        local pyroType = pyroConfig.type or 'flame'
        local intensity = pyroConfig.intensity or 1.0
        local height = pyroConfig.height or 3.0
        local syncWithMusic = pyroConfig.syncWithMusic or false
        
        print(string.format("[DJ Pyro] Type: %s, Sync: %s", pyroType, tostring(syncWithMusic)))
        
        -- Load particle assets
        local dict1 = "scr_indep_fireworks"
        local dict2 = "core"
        RequestNamedPtfxAsset(dict1)
        RequestNamedPtfxAsset(dict2)
        while not HasNamedPtfxAssetLoaded(dict1) or not HasNamedPtfxAssetLoaded(dict2) do Wait(10) end
        
        print("[DJ Pyro] ✓ Assets loaded")
        
        local frameCount = 0
        local lastBurst = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local currentTime = GetGameTimer()
                
                local currentIntensity = intensity
                local shouldBurst = false
            
            -- Music sync
            if syncWithMusic and musicBeat.isPlaying then
                if IsOnBeat() and (currentTime - lastBurst) > 400 then
                    currentIntensity = intensity * 2
                    shouldBurst = true
                    lastBurst = currentTime
                    if frameCount % 60 == 0 then
                        print("[DJ Pyro] ♪ ON BEAT! Pyro burst")
                    end
                end
            end
            
            if pyroType == 'flame' then
                -- LANÇA-CHAMAS PROFISSIONAL (como shows de verdade)
                if shouldBurst or (not syncWithMusic and frameCount % 30 == 0) then  -- MAIS FREQUENTE
                    -- EXPLOSÃO DE CHAMAS MASSIVA (QUINTUPLICADO)
                    for i = 1, 8 do
                        local offsetX = math.random(-40, 40) / 100
                        local offsetY = math.random(-40, 40) / 100
                        local offsetZ = math.random(0, 100) / 100
                        
                        UseParticleFxAssetNextCall(dict2)
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_flare",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 0.5 + offsetZ,
                            0.0, 0.0, 0.0,
                            currentIntensity * 6.0, false, false, false  -- MUITO MAIS INTENSO
                        )
                    end
                    
                    -- COLUNA DE FOGO (partículas em altura)
                    for h = 1, 5 do
                        UseParticleFxAssetNextCall(dict2)
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_flare",
                            coords.x, coords.y, coords.z + (h * 0.8),
                            0.0, 0.0, 0.0,
                            currentIntensity * 4.0, false, false, false
                        )
                    end
                    
                    -- LUZES EM MÚLTIPLAS ALTURAS (coluna de fogo)
                    for h = 1, 6 do
                        DrawLightWithRange(
                            coords.x, coords.y, coords.z + (h * 0.7),
                            r, g, b,
                            18.0 - (h * 1.5),
                            currentIntensity * (35 - h * 3)
                        )
                    end
                    
                    -- LUZ CENTRAL ULTRA BRILHANTE
                    DrawLightWithRange(coords.x, coords.y, coords.z + height, r, g, b, 20.0, currentIntensity * 50)
                    
                    -- GLOW NO CHÃO MASSIVO
                    DrawMarker(
                        25,
                        coords.x, coords.y, coords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        12.0, 12.0, 0.1,
                        r, g, b, 255,
                        false, false, 2, false, nil, nil, false
                    )
                    
                    -- ONDAS DE CALOR (NOVO - efeito visual)
                    for ring = 1, 3 do
                        DrawMarker(
                            25,
                            coords.x, coords.y, coords.z + (ring * 0.5),
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            8.0 + (ring * 2), 8.0 + (ring * 2), 0.1,
                            r, g, b, 100 - (ring * 20),
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
                
            elseif pyroType == 'firework' then
                -- Firework burst
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > 3000) then
                    lastBurst = currentTime
                    
                    UseParticleFxAssetNextCall(dict1)
                    StartParticleFxNonLoopedAtCoord(
                        "scr_indep_firework_starburst",
                        coords.x, coords.y, coords.z + height,
                        0.0, 0.0, 0.0,
                        currentIntensity * 2, false, false, false
                    )
                    
                    DrawLightWithRange(coords.x, coords.y, coords.z + height, r, g, b, 15.0, 25.0)
                end
                
            elseif pyroType == 'sparkler' then
                -- Continuous sparkles
                for i = 1, math.floor(currentIntensity * 3) do
                    local offsetX = math.random(-30, 30) / 100
                    local offsetY = math.random(-30, 30) / 100
                    
                    UseParticleFxAssetNextCall(dict1)
                    StartParticleFxNonLoopedAtCoord(
                        "scr_indep_firework_sparkle_spawn",
                        coords.x + offsetX, coords.y + offsetY, coords.z + 1.0,
                        0.0, 0.0, 0.0,
                        currentIntensity, false, false, false
                    )
                end
                
            elseif pyroType == 'fountain' then
                -- Fountain effect
                UseParticleFxAssetNextCall(dict1)
                StartParticleFxNonLoopedAtCoord(
                    "scr_indep_firework_fountain",
                    coords.x, coords.y, coords.z + 0.2,
                    0.0, 0.0, 0.0,
                    currentIntensity * 1.5, false, false, false
                )
                
                DrawLightWithRange(coords.x, coords.y, coords.z + 1.0, r, g, b, 8.0, currentIntensity * 10)
            end
            
            Wait(syncWithMusic and 50 or 100)
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 50 or 500)
        end
        
        print("[DJ Pyro] Effect stopped")
    end)
end

-- CO2 Jets Effect System (High-pressure gas effects)
function StartCO2Effect(entity, effectId, co2Config)
    print("[DJ CO2] Starting CO2 JETS effect")
    
    Citizen.CreateThread(function()
        local mode = co2Config.mode or 'vertical'
        local pressure = co2Config.pressure or 1.0
        local duration = co2Config.duration or 2.0
        local syncWithMusic = co2Config.syncWithMusic or false
        
        print(string.format("[DJ CO2] Mode: %s, Sync: %s", mode, tostring(syncWithMusic)))
        
        -- Load particle assets
        local dict = "core"
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
        
        print("[DJ CO2] ✓ Assets loaded")
        
        local frameCount = 0
        local lastBurst = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local currentTime = GetGameTimer()
                
                local currentPressure = pressure
                local shouldBurst = false
            
            -- Music sync
            if syncWithMusic and musicBeat.isPlaying then
                if IsOnBeat() and (currentTime - lastBurst) > 400 then
                    currentPressure = pressure * 2
                    shouldBurst = true
                    lastBurst = currentTime
                    if frameCount % 60 == 0 then
                        print("[DJ CO2] ♪ ON BEAT! CO2 blast")
                    end
                end
            end
            
            if mode == 'vertical' then
                -- JATO DE CO2 VERTICAL PROFISSIONAL (como shows grandes)
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > duration * 1000) then
                    lastBurst = currentTime
                    
                    -- JATO PRINCIPAL MASSIVO (TRIPLICADO)
                    for i = 1, math.floor(currentPressure * 25) do
                        local offsetX = math.random(-25, 25) / 100
                        local offsetY = math.random(-25, 25) / 100
                        local offsetZ = math.random(0, 200) / 100
                        
                        UseParticleFxAssetNextCall(dict)
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_bzgas_smoke",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 0.5 + offsetZ,
                            0.0, 0.0, 0.0,
                            currentPressure * 8, false, false, false  -- MUITO MAIS INTENSO
                        )
                    end
                    
                    -- CAMADAS SUPERIORES (jato alto)
                    for layer = 1, 4 do
                        for i = 1, math.floor(currentPressure * 8) do
                            local offsetX = math.random(-20, 20) / 100
                            local offsetY = math.random(-20, 20) / 100
                            
                            UseParticleFxAssetNextCall(dict)
                            StartParticleFxNonLoopedAtCoord(
                                "exp_grd_grenade_smoke",
                                coords.x + offsetX, coords.y + offsetY, coords.z + (layer * 1.5),
                                0.0, 0.0, 0.0,
                                currentPressure * (6 - layer * 0.5), false, false, false
                            )
                        end
                    end
                    
                    -- COLUNA DE LUZ BRANCA ULTRA BRILHANTE
                    for h = 1, 8 do
                        DrawLightWithRange(
                            coords.x, coords.y, coords.z + (h * 0.8),
                            255, 255, 255,
                            15.0 - (h * 0.8),
                            currentPressure * (30 - h * 2)
                        )
                    end
                    
                    -- LUZ CENTRAL MASSIVA
                    DrawLightWithRange(coords.x, coords.y, coords.z + 4.0, 255, 255, 255, 20.0, currentPressure * 50)
                    
                    -- GLOW NO CHÃO
                    DrawMarker(
                        25,
                        coords.x, coords.y, coords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        10.0, 10.0, 0.1,
                        255, 255, 255, 255,
                        false, false, 2, false, nil, nil, false
                    )
                    
                    -- ONDAS DE PRESSÃO (NOVO)
                    for ring = 1, 4 do
                        DrawMarker(
                            25,
                            coords.x, coords.y, coords.z + (ring * 1.2),
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            6.0 + (ring * 1.5), 6.0 + (ring * 1.5), 0.1,
                            255, 255, 255, 150 - (ring * 25),
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
                
            elseif mode == 'horizontal' then
                -- Horizontal blast
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > duration * 1000) then
                    lastBurst = currentTime
                    
                    for angle = 0, 360, 45 do
                        local rad = math.rad(angle)
                        local offsetX = math.cos(rad) * 0.5
                        local offsetY = math.sin(rad) * 0.5
                        
                        UseParticleFxAssetNextCall(dict)
                        StartParticleFxNonLoopedAtCoord(
                            "exp_grd_bzgas_smoke",
                            coords.x + offsetX, coords.y + offsetY, coords.z + 1.0,
                            0.0, 0.0, 0.0,
                            currentPressure * 2, false, false, false
                        )
                    end
                end
                
            elseif mode == 'burst' then
                -- Quick burst
                if shouldBurst or (not syncWithMusic and (currentTime - lastBurst) > 1000) then
                    lastBurst = currentTime
                    
                    UseParticleFxAssetNextCall(dict)
                    StartParticleFxNonLoopedAtCoord(
                        "exp_grd_grenade_smoke",
                        coords.x, coords.y, coords.z + 0.5,
                        0.0, 0.0, 0.0,
                        currentPressure * 4, false, false, false
                    )
                end
                
            elseif mode == 'continuous' then
                -- Continuous stream
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(
                    "exp_grd_bzgas_smoke",
                    coords.x, coords.y, coords.z + 0.5,
                    0.0, 0.0, 0.0,
                    currentPressure, false, false, false
                )
            end
            
            Wait(syncWithMusic and 50 or 200)
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 50 or 500)
        end
        
        print("[DJ CO2] Effect stopped")
    end)
end

-- UV Lights Effect System (Blacklight/Neon effects)
function StartUVEffect(entity, effectId, uvConfig)
    print("[DJ UV] Starting UV LIGHTS effect")
    
    Citizen.CreateThread(function()
        local r, g, b = HexToRGB(uvConfig.color or "#9900ff")
        local pattern = uvConfig.pattern or 'static'
        local intensity = uvConfig.intensity or 5.0
        local range = uvConfig.range or 15
        local syncWithMusic = uvConfig.syncWithMusic or false
        
        print(string.format("[DJ UV] Pattern: %s, Sync: %s", pattern, tostring(syncWithMusic)))
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            frameCount = frameCount + 1
            
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local time = GetGameTimer() / 1000.0
                
                local currentIntensity = intensity
                local currentR, currentG, currentB = r, g, b
            
            -- Music sync
            if syncWithMusic and musicBeat.isPlaying then
                if frameCount == 1 then
                    print("[DJ UV] ✓ Music sync ACTIVE")
                end
                
                if IsOnBeat() then
                    currentIntensity = intensity * 2
                    if frameCount % 60 == 0 then
                        print("[DJ UV] ♪ ON BEAT! UV boost")
                    end
                end
                
                local beatPhase = GetBeatPhase()
                currentIntensity = currentIntensity * (0.5 + beatPhase * 0.5)
            end
            
            if pattern == 'static' then
                -- LUZ UV ESTÁTICA PROFISSIONAL (blacklight intenso)
                -- Múltiplas camadas de luz UV
                for h = 1, 5 do
                    DrawLightWithRange(
                        coords.x, coords.y, coords.z + (h * 0.8),
                        currentR, currentG, currentB,
                        range + (h * 2),
                        currentIntensity * (4 - h * 0.3)
                    )
                end
                
                -- Luz central ULTRA BRILHANTE
                DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, currentR, currentG, currentB, range * 1.5, currentIntensity * 5)
                
                -- GLOW NO CHÃO MASSIVO
                DrawMarker(
                    25,
                    coords.x, coords.y, coords.z - 0.98,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    range * 1.5, range * 1.5, 0.1,
                    currentR, currentG, currentB, math.floor(currentIntensity * 15),
                    false, false, 2, false, nil, nil, false
                )
                
                -- ONDAS DE LUZ UV (NOVO)
                for ring = 1, 3 do
                    DrawMarker(
                        25,
                        coords.x, coords.y, coords.z + (ring * 0.5),
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        range * (1 + ring * 0.3), range * (1 + ring * 0.3), 0.1,
                        currentR, currentG, currentB, math.floor(currentIntensity * (10 - ring * 2)),
                        false, false, 2, false, nil, nil, false
                    )
                end
                
                -- NÉVOA UV VOLUMÉTRICA (NOVO)
                for layer = 1, 4 do
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + (layer * 0.7),
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        range * 0.8, range * 0.8, 2.0,
                        currentR, currentG, currentB, 30 + (layer * 5),
                        false, false, 2, false, nil, nil, false
                    )
                end
                
            elseif pattern == 'pulse' then
                -- Pulsing UV
                local pulse = (math.sin(time * 2) + 1) / 2
                local pulseIntensity = currentIntensity * pulse
                
                DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, currentR, currentG, currentB, range, pulseIntensity * 2)
                
                -- Ground pulse
                DrawMarker(
                    25,
                    coords.x, coords.y, coords.z - 0.98,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    range, range, 0.1,
                    currentR, currentG, currentB, math.floor(pulseIntensity * 8),
                    false, false, 2, false, nil, nil, false
                )
                
            elseif pattern == 'wave' then
                -- Wave pattern
                for i = 1, 8 do
                    local angle = (time * 50 + (i * 45)) % 360
                    local rad = math.rad(angle)
                    local dist = range * 0.7
                    local lx = coords.x + math.cos(rad) * dist
                    local ly = coords.y + math.sin(rad) * dist
                    
                    DrawLightWithRange(lx, ly, coords.z + 1.0, currentR, currentG, currentB, range * 0.3, currentIntensity)
                end
                
            elseif pattern == 'strobe' then
                -- UV strobe
                local strobe
                
                if syncWithMusic and musicBeat.isPlaying then
                    strobe = IsOnBeat() and 1 or 0
                else
                    strobe = math.floor(time * 10) % 2
                end
                
                if strobe == 1 then
                    DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, currentR, currentG, currentB, range * 1.5, currentIntensity * 3)
                    
                    -- Ground flash
                    DrawMarker(
                        25,
                        coords.x, coords.y, coords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        range * 1.5, range * 1.5, 0.1,
                        currentR, currentG, currentB, 255,
                        false, false, 2, false, nil, nil, false
                    )
                end
            end
            end -- End of IsMusicPlayingInZone check
            
            Wait(IsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ UV] Effect stopped")
    end)
end

-- ========================================
-- MUSIC SYNCHRONIZATION SYSTEM
-- ========================================

-- musicBeat is defined at the top of the file

-- Function to check if we're on a beat
function IsOnBeat()
    if not musicBeat.isPlaying then return false end
    
    local currentTime = GetGameTimer()
    local beatInterval = (60000 / musicBeat.bpm) -- ms per beat
    local timeSinceBeat = currentTime - musicBeat.lastBeatTime
    
    -- Consider "on beat" if within 200ms of the last beat (increased window)
    -- This gives effects more time to react to the beat
    return timeSinceBeat < 200
end

-- Function to get beat phase (0.0 to 1.0)
function GetBeatPhase()
    if not musicBeat.isPlaying then return 0 end
    
    local currentTime = GetGameTimer()
    local beatInterval = (60000 / musicBeat.bpm)
    local timeSinceBeat = (currentTime - musicBeat.lastBeatTime) % beatInterval
    
    return timeSinceBeat / beatInterval
end

-- Receive beat from server (synchronized across all clients)
RegisterNetEvent('dj:receiveBeat')
AddEventHandler('dj:receiveBeat', function(zoneId, bpm)
    print("========================================")
    print("[DJ Beat] 📡 BEAT RECEIVED FROM SERVER!")
    print(string.format("[DJ Beat] Zone: %s | BPM: %d", tostring(zoneId), bpm))
    
    musicBeat.bpm = bpm or 128
    musicBeat.lastBeatTime = GetGameTimer()
    musicBeat.beat = (musicBeat.beat + 1) % 4
    musicBeat.isPlaying = true
    
    print(string.format("[DJ Beat] ✓ State updated: Beat %d/4 | Time: %d", musicBeat.beat, GetGameTimer()))
    print(string.format("[DJ Beat] IsOnBeat(): %s", tostring(IsOnBeat())))
    print("========================================")
end)

-- Sync music state from server
RegisterNetEvent('dj:syncMusicState')
AddEventHandler('dj:syncMusicState', function(zoneId, state)
    musicBeat.isPlaying = state.playing
    musicBeat.bpm = state.bpm or 128
    
    if state.playing then
        musicBeat.lastBeatTime = GetGameTimer()
    end
end)

-- Beat simulation removed - now using real beat detection from audio

-- Helper: Check if music is playing in entity's zone
function IsMusicPlayingInZone(entity)
    local zoneId = Entity(entity).state.zoneId
    if not zoneId or not audioZones[zoneId] then
        return false
    end
    
    -- Check if any deck is playing in this zone
    return musicBeat.isPlaying
end

-- Helper: Wrapper for effect loops - only runs when music is playing
function ShouldShowEffect(entity)
    return IsMusicPlayingInZone(entity)
end

-- Helper: Hex to RGB
function HexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

-- Helper: HSV to RGB
function HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h / 60)
    local f = h / 60 - i
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


