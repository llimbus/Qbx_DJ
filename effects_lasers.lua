-- ============================================
-- LASER SHOW - Efeitos de Laser
-- ============================================
-- Requer: effects_core.lua
-- ============================================

print("[DJ Effects] Loading laser show module...")

function DJStartLaserShowEffect(entity, effectId, laserConfig)
    print("[DJ Laser] Starting ENHANCED LASER SHOW effect")
    
    Citizen.CreateThread(function()
        local r, g, b = DJHexToRGB(laserConfig.color or "#00ff00")
        local pattern = laserConfig.pattern or 'beams'
        local count = laserConfig.count or 4
        local speed = laserConfig.speed or 1.0
        local syncWithMusic = laserConfig.syncWithMusic or false
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and DJIsEffectActive(entity, effectId) do
            frameCount = frameCount + 1
            
            if DJIsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local time = GetGameTimer() / (1000 / speed)
                
                local currentIntensity = 8.0
                local currentCount = count
                local currentR, currentG, currentB = r, g, b
                
                -- Sincronização com música
                if syncWithMusic and DJMusicBeat.isPlaying then
                    if DJIsOnBeat() then
                        currentIntensity = currentIntensity * 4.0
                        currentCount = math.min(count * 3, 16)
                        local beatPhase = DJGetBeatPhase()
                        local flashFactor = 1.0 + (1.0 - beatPhase) * 2.0
                        currentIntensity = currentIntensity * flashFactor
                    else
                        currentIntensity = currentIntensity * (0.3 + DJGetBeatPhase() * 0.7)
                    end
                    
                    if DJIsOnBeat() then
                        time = time * 2.0
                    end
                    
                    if (pattern == 'random' or pattern == 'rainbow') and DJIsOnBeat() then
                        local hue = (DJMusicBeat.beat * 90) % 360
                        currentR, currentG, currentB = DJHSVToRGB(hue, 1, 1)
                    end
                end
                
                if pattern == 'beams' then
                    -- Lasers rotativos ultra realistas
                    for i = 1, currentCount do
                        local angle = (time * 30 + (i * (360 / currentCount))) % 360
                        local rad = math.rad(angle)
                        local distance = 50.0
                        local height = math.sin(time * 0.5 + i) * 7.0
                        local endX = coords.x + math.cos(rad) * distance
                        local endY = coords.y + math.sin(rad) * distance
                        local endZ = coords.z + 2.5 + height
                        
                        -- Beam volumétrico grosso (5 linhas paralelas)
                        for j = 0, 4 do
                            local offset = (j - 2) * 0.12
                            local offsetX = math.cos(rad + math.pi/2) * offset
                            local offsetY = math.sin(rad + math.pi/2) * offset
                            
                            DrawLine(coords.x + offsetX, coords.y + offsetY, coords.z + 2.5,
                                endX + offsetX, endY + offsetY, endZ,
                                currentR, currentG, currentB, 255)
                        end
                        
                        -- Luzes ao longo do beam
                        for step = 0, 1, 0.15 do
                            local stepX = coords.x + (endX - coords.x) * step
                            local stepY = coords.y + (endY - coords.y) * step
                            local stepZ = coords.z + 2.5 + (endZ - (coords.z + 2.5)) * step
                            
                            DrawLightWithRange(stepX, stepY, stepZ, currentR, currentG, currentB,
                                5.0 + (step * 4), currentIntensity * (4 - step * 2))
                        end
                        
                        -- Endpoint glow massivo
                        DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 10.0, currentIntensity * 3)
                        
                        -- Marker no endpoint
                        DrawMarker(25, endX, endY, endZ - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            6.0, 6.0, 0.1, currentR, currentG, currentB, 200,
                            false, false, 2, false, nil, nil, false)
                        
                        -- Origin glow
                        DrawLightWithRange(coords.x, coords.y, coords.z + 2.5, currentR, currentG, currentB, 8.0, currentIntensity * 2)
                    end
                    
                elseif pattern == 'grid' then
                    -- Padrão de grade dinâmica
                    local gridSize = 15.0
                    local gridSpacing = 2.5
                    
                    for i = -3, 3 do
                        local offsetX = i * gridSpacing
                        DrawLine(coords.x + offsetX, coords.y - gridSize, coords.z + 4.0,
                            coords.x + offsetX, coords.y + gridSize, coords.z + 4.0,
                            currentR, currentG, currentB, 220)
                    end
                    
                    for i = -6, 6 do
                        local offsetY = i * gridSpacing
                        DrawLine(coords.x - gridSize, coords.y + offsetY, coords.z + 4.0,
                            coords.x + gridSize, coords.y + offsetY, coords.z + 4.0,
                            currentR, currentG, currentB, 220)
                    end
                    
                elseif pattern == 'spiral' then
                    -- Padrão espiral
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
                    -- Varredura aleatória
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
            end
            
            Wait(DJIsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ Laser] Effect stopped")
    end)
end


print("[DJ Effects] ✓ Laser show module loaded")
