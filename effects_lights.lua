-- ============================================
-- STAGE LIGHTS - Luzes Profissionais de Palco
-- ============================================
-- Requer: effects_core.lua
-- ============================================

print("[DJ Effects] Loading stage lights module...")

function DJStartStageLightsEffect(entity, effectId, lightConfig)
    print("[DJ Light] Starting VOLUMETRIC STAGE LIGHTS")
    print("[DJ Light] Effect ID:", effectId)
    
    Citizen.CreateThread(function()
        local r, g, b = DJHexToRGB(lightConfig.color or "#00ffff")
        local mode = lightConfig.mode or 'movinghead'
        local speed = lightConfig.speed or 1.0
        local intensity = lightConfig.intensity or 5.0
        local syncWithMusic = lightConfig.syncWithMusic or false
        
        local frameCount = 0
        
        while DoesEntityExist(entity) and DJIsEffectActive(entity, effectId) do
            frameCount = frameCount + 1
            
            if DJIsMusicPlayingInZone(entity) then
                local time = GetGameTimer() / 1000.0
                local coords = GetEntityCoords(entity)
                local currentR, currentG, currentB = r, g, b
                local currentIntensity = intensity * 8.0
                
                -- Sincronização com música
                if syncWithMusic and DJMusicBeat.isPlaying then
                    local onBeat = DJIsOnBeat()
                    local beatPhase = DJGetBeatPhase()
                    
                    if onBeat then
                        currentIntensity = currentIntensity * 3.0
                        local pulseFactor = 1.0 + (1.0 - beatPhase) * 0.5
                        currentIntensity = currentIntensity * pulseFactor
                    else
                        local fadeFactor = 0.5 + (beatPhase * 0.5)
                        currentIntensity = currentIntensity * fadeFactor
                    end
                end
                
                -- MOVING HEAD
                if mode == 'movinghead' then
                    local numBeams = 6
                    local beamHeight = 6.0
                    local beamDistance = 15.0
                    
                    for layer = 1, 3 do
                        DrawMarker(28, coords.x, coords.y, coords.z + (layer * 2), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            20.0, 20.0, 4.0, currentR, currentG, currentB, 15 + (layer * 5),
                            false, false, 2, false, nil, nil, false)
                    end
                    
                    for i = 1, numBeams do
                        local angle = (time * 25 * speed + (i * (360 / numBeams))) % 360
                        local rad = math.rad(angle)
                        local tilt = math.sin(time * 0.6 + i) * 0.2
                        
                        local dirX = math.cos(rad) * 0.6
                        local dirY = math.sin(rad) * 0.6
                        local dirZ = -0.85 + tilt
                        
                        local originX, originY, originZ = coords.x, coords.y, coords.z + beamHeight
                        local endX = originX + dirX * beamDistance
                        local endY = originY + dirY * beamDistance
                        local endZ = coords.z - 0.5
                        
                        DrawSpotLight(originX, originY, originZ, dirX, dirY, dirZ,
                            currentR, currentG, currentB, beamDistance * 2.5, currentIntensity * 20, 0.0, 12.0, 45.0)
                        
                        for lineOffset = -0.3, 0.3, 0.15 do
                            local perpX = -math.sin(rad) * lineOffset
                            local perpY = math.cos(rad) * lineOffset
                            DrawLine(originX + perpX, originY + perpY, originZ,
                                endX + perpX, endY + perpY, endZ,
                                currentR, currentG, currentB, 200)
                        end
                        
                        for step = 0, 1, 0.2 do
                            local stepX = originX + (endX - originX) * step
                            local stepY = originY + (endY - originY) * step
                            local stepZ = originZ + (endZ - originZ) * step
                            DrawLightWithRange(stepX, stepY, stepZ, currentR, currentG, currentB,
                                4.0 + (step * 3), currentIntensity * (3 - step * 2))
                        end
                        
                        DrawLightWithRange(originX, originY, originZ, currentR, currentG, currentB, 8.0, currentIntensity * 8)
                        DrawLightWithRange(endX, endY, endZ, currentR, currentG, currentB, 12.0, currentIntensity * 10)
                        
                        DrawMarker(25, endX, endY, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            10.0, 10.0, 0.1, currentR, currentG, currentB, 240,
                            false, false, 2, false, nil, nil, false)
                    end
                    
                    DrawMarker(28, coords.x, coords.y, coords.z + 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        25.0, 25.0, 1.0, currentR, currentG, currentB, 40,
                        false, false, 2, false, nil, nil, false)
                
                -- STROBE
                elseif mode == 'strobe' then
                    local strobe
                    if syncWithMusic and DJMusicBeat.isPlaying then
                        strobe = DJIsOnBeat() and 1 or 0
                    else
                        strobe = math.floor(GetGameTimer() / (40 / speed)) % 2
                    end
                    
                    if strobe == 1 then
                        local strobeIntensity = intensity * 20
                        for i = 1, 20 do
                            local angle = i * 18
                            local rad = math.rad(angle)
                            local lx = coords.x + math.cos(rad) * 6.0
                            local ly = coords.y + math.sin(rad) * 6.0
                            DrawLightWithRange(lx, ly, coords.z + 2.0, 255, 255, 255, 20.0, strobeIntensity * 3)
                        end
                        for h = 1, 5 do
                            DrawLightWithRange(coords.x, coords.y, coords.z + h, 255, 255, 255, 25.0, strobeIntensity * 4)
                        end
                        DrawMarker(25, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            40.0, 40.0, 0.1, 255, 255, 255, 255, false, false, 2, false, nil, nil, false)
                    end
                
                -- Outros modos (wash, disco, scanner, chase, rainbow, pulse)
                -- ... (código similar ao original)
                
                end
            end
            
            Wait(DJIsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ Light] Effect stopped")
    end)
end

print("[DJ Effects] ✓ Stage lights module loaded")
