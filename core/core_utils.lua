-- ============================================
-- QBXDJ - CORE UTILS MODULE
-- ============================================
-- Funções utilitárias compartilhadas
-- Requer: core_shared.lua
-- ============================================
-- Data de Criação: 05/12/2025
-- Versão: 2.0.0
-- Autor: llimbus
-- ============================================

print("[DJ Utils] Loading utils module...")

-- ============================================
-- NAMESPACE
-- ============================================

DJUtils = {}

-- ============================================
-- CONVERSÕES DE COR
-- ============================================

-- Converter HEX para RGB
-- @param hex string - Cor em hexadecimal (ex: "#FF0000")
-- @return number, number, number - R, G, B (0-255)
function DJUtils.HexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))
    return r, g, b
end

-- Converter RGB para HEX
-- @param r number - Red (0-255)
-- @param g number - Green (0-255)
-- @param b number - Blue (0-255)
-- @return string - Cor em hexadecimal
function DJUtils.RGBToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Converter HSV para RGB
-- @param h number - Hue (0-360)
-- @param s number - Saturation (0-1)
-- @param v number - Value (0-1)
-- @return number, number, number - R, G, B (0-255)
function DJUtils.HSVToRGB(h, s, v)
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

-- ============================================
-- CÁLCULOS MATEMÁTICOS
-- ============================================

-- Calcular distância entre dois pontos
-- @param coords1 vector3 - Primeira coordenada
-- @param coords2 vector3 - Segunda coordenada
-- @return number - Distância
function DJUtils.GetDistance(coords1, coords2)
    return #(coords1 - coords2)
end

-- Calcular distância 2D (ignora Z)
-- @param coords1 vector3 - Primeira coordenada
-- @param coords2 vector3 - Segunda coordenada
-- @return number - Distância 2D
function DJUtils.GetDistance2D(coords1, coords2)
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Interpolar entre dois valores
-- @param a number - Valor inicial
-- @param b number - Valor final
-- @param t number - Fator de interpolação (0-1)
-- @return number - Valor interpolado
function DJUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Clampar valor entre min e max
-- @param value number - Valor
-- @param min number - Mínimo
-- @param max number - Máximo
-- @return number - Valor clampado
function DJUtils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- ============================================
-- RAYCAST
-- ============================================

-- Raycast da câmera do jogador
-- @param distance number - Distância máxima
-- @return boolean, vector3, vector3, number - hit, coords, surfaceNormal, entityHit
function DJUtils.RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = DJUtils.RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(
        StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z,
                         destination.x, destination.y, destination.z,
                         -1, PlayerPedId(), 0)
    )
    return b, c, d, e
end

-- Converter rotação para direção
-- @param rotation vector3 - Rotação
-- @return table - Direção {x, y, z}
function DJUtils.RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

-- ============================================
-- NOTIFICAÇÕES
-- ============================================

-- Enviar notificação para o jogador
-- @param message string - Mensagem
-- @param type string - Tipo ('info', 'success', 'warning', 'error')
-- @param duration number - Duração em ms (opcional)
function DJUtils.Notify(message, type, duration)
    type = type or 'info'
    duration = duration or (Config and Config.NotificationDuration or 3000)
    
    -- Tentar usar sistema de notificação do framework
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = 'DJ System',
            description = message,
            type = type,
            duration = duration
        })
    elseif GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', message, type, duration)
    else
        -- Fallback: notificação nativa
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end
end

-- ============================================
-- LOGGING
-- ============================================

-- Sistema de logs
-- @param level string - Nível ('debug', 'info', 'warn', 'error')
-- @param message string - Mensagem
-- @param ... any - Argumentos adicionais
function DJUtils.Log(level, message, ...)
    level = level or 'info'
    
    -- Verificar se deve logar
    if Config and Config.LogLevel then
        local levels = { debug = 1, info = 2, warn = 3, error = 4 }
        local configLevel = levels[Config.LogLevel] or 2
        local currentLevel = levels[level] or 2
        
        if currentLevel < configLevel then
            return
        end
    end
    
    -- Formatar mensagem
    local prefix = string.format("[DJ %s]", level:upper())
    local fullMessage = string.format(message, ...)
    
    -- Colorir por nível
    local color = "^7" -- Branco
    if level == 'debug' then color = "^5" -- Roxo
    elseif level == 'info' then color = "^2" -- Verde
    elseif level == 'warn' then color = "^3" -- Amarelo
    elseif level == 'error' then color = "^1" -- Vermelho
    end
    
    print(color .. prefix .. "^7 " .. fullMessage)
    
    -- Salvar em arquivo se configurado
    if Config and Config.LogToFile then
        -- TODO: Implementar salvamento em arquivo
    end
end

-- Atalhos para logs
function DJUtils.Debug(...) DJUtils.Log('debug', ...) end
function DJUtils.Info(...) DJUtils.Log('info', ...) end
function DJUtils.Warn(...) DJUtils.Log('warn', ...) end
function DJUtils.Error(...) DJUtils.Log('error', ...) end

-- ============================================
-- VALIDAÇÃO
-- ============================================

-- Validar URL
-- @param url string - URL
-- @return boolean - Válida ou não
function DJUtils.IsValidURL(url)
    if not url or type(url) ~= 'string' then
        return false
    end
    
    -- Verificar se é YouTube
    if url:match("youtube%.com") or url:match("youtu%.be") then
        return true
    end
    
    -- Verificar se é URL de áudio direto
    local audioFormats = { 'mp3', 'ogg', 'wav', 'm4a', 'aac', 'flac', 'opus', 'webm' }
    for _, format in ipairs(audioFormats) do
        if url:match("%." .. format) then
            return true
        end
    end
    
    return false
end

-- Validar modelo de prop
-- @param model string - Nome do modelo
-- @return boolean - Válido ou não
function DJUtils.IsValidPropModel(model)
    if not model or type(model) ~= 'string' then
        return false
    end
    
    -- Verificar se está na lista de modelos nativos
    for _, propModel in pairs(DJSystem.PropModels) do
        if model == propModel then
            return true
        end
    end
    
    return false
end

-- Sanitizar string
-- @param str string - String
-- @return string - String sanitizada
function DJUtils.Sanitize(str)
    if not str or type(str) ~= 'string' then
        return ""
    end
    
    -- Remover caracteres perigosos
    str = str:gsub("[<>\"']", "")
    
    return str
end

-- ============================================
-- FORMATAÇÃO
-- ============================================

-- Formatar tempo (ms para MM:SS)
-- @param ms number - Tempo em milissegundos
-- @return string - Tempo formatado
function DJUtils.FormatTime(ms)
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

-- Formatar número com separador de milhares
-- @param number number - Número
-- @return string - Número formatado
function DJUtils.FormatNumber(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- ============================================
-- TABELAS
-- ============================================

-- Copiar tabela (deep copy)
-- @param orig table - Tabela original
-- @return table - Cópia da tabela
function DJUtils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DJUtils.DeepCopy(orig_key)] = DJUtils.DeepCopy(orig_value)
        end
        setmetatable(copy, DJUtils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Contar elementos em tabela
-- @param tbl table - Tabela
-- @return number - Número de elementos
function DJUtils.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Verificar se tabela está vazia
-- @param tbl table - Tabela
-- @return boolean - Vazia ou não
function DJUtils.IsTableEmpty(tbl)
    return next(tbl) == nil
end

-- ============================================
-- STRINGS
-- ============================================

-- Dividir string
-- @param str string - String
-- @param delimiter string - Delimitador
-- @return table - Array de strings
function DJUtils.Split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

-- Trim string (remover espaços)
-- @param str string - String
-- @return string - String sem espaços nas pontas
function DJUtils.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

print("[DJ Utils] ✓ Utils module loaded successfully")
