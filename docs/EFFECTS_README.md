# 🎨 Sistema Modular de Efeitos Visuais

## 📋 Visão Geral

O sistema de efeitos visuais foi modularizado para facilitar a manutenção e personalização. Agora você pode modificar apenas os arquivos de efeitos sem tocar no código principal.

## 📁 Estrutura de Arquivos

```
Qbx_DJ/
├── effects.lua              # Funções auxiliares + Stage Lights + Smoke
├── effects_lasers.lua       # Efeitos de laser
├── effects_particles.lua    # Confetti, Bubbles (a criar)
├── effects_pyro.lua         # Pyro, CO2, UV (a criar)
├── client.lua               # Código principal (não modificar efeitos aqui)
└── fxmanifest.lua           # Carrega os módulos na ordem correta
```

## 🎯 Como Funciona

### 1. Ordem de Carregamento

O `fxmanifest.lua` carrega os arquivos nesta ordem:

```lua
client_scripts {
    'effects.lua',           -- Carregado primeiro (funções auxiliares)
    'effects_lasers.lua',    -- Efeitos de laser
    'client.lua'             -- Código principal
}
```

### 2. Funções Auxiliares (effects.lua)

Funções compartilhadas por todos os efeitos:

- `HexToRGB(hex)` - Converte cor hexadecimal para RGB
- `HSVToRGB(h, s, v)` - Converte HSV para RGB
- `IsOnBeat()` - Verifica se está no beat da música
- `GetBeatPhase()` - Retorna fase do beat (0.0 a 1.0)
- `IsMusicPlayingInZone(entity)` - Verifica se música está tocando

### 3. Efeitos Implementados

#### effects.lua
- ✅ `StartStageLightsEffect()` - Luzes de palco profissionais
- ✅ `StartSmokeEffect()` - Máquina de fumaça

#### effects_lasers.lua
- ✅ `StartLaserShowEffect()` - Show de lasers

#### A Implementar
- ⏳ `StartConfettiEffect()` - Confetes
- ⏳ `StartBubblesEffect()` - Bolhas
- ⏳ `StartPyroEffect()` - Pirotecnia
- ⏳ `StartCO2Effect()` - Jatos de CO2
- ⏳ `StartUVEffect()` - Luzes UV
- ⏳ `StartFireworkEffect()` - Fogos de artifício

## 🛠️ Como Modificar Efeitos

### Exemplo: Modificar Intensidade dos Lasers

1. Abra `effects_lasers.lua`
2. Encontre a função `StartLaserShowEffect`
3. Modifique os valores:

```lua
-- ANTES
local currentIntensity = 8.0

-- DEPOIS (mais intenso)
local currentIntensity = 15.0
```

### Exemplo: Adicionar Novo Modo de Luz

1. Abra `effects.lua`
2. Encontre a função `StartStageLightsEffect`
3. Adicione um novo modo:

```lua
elseif mode == 'meu_modo' then
    -- Seu código aqui
    for i = 1, 10 do
        DrawLightWithRange(coords.x, coords.y, coords.z + i, 
            currentR, currentG, currentB, 10.0, currentIntensity)
    end
```

4. Use no jogo com:
```lua
effectConfig = {
    type = 'lights',
    lights = {
        mode = 'meu_modo',
        color = '#ff0000',
        intensity = 5.0
    }
}
```

## 🎨 Configurações Disponíveis

### Stage Lights (Luzes de Palco)

```lua
{
    type = 'lights',
    lights = {
        color = '#00ffff',           -- Cor em hexadecimal
        mode = 'movinghead',         -- movinghead, strobe, wash, disco, scanner, chase, rainbow, pulse
        speed = 1.0,                 -- Velocidade (0.1 a 5.0)
        intensity = 5.0,             -- Intensidade (1.0 a 10.0)
        syncWithMusic = true         -- Sincronizar com batida
    }
}
```

### Smoke (Fumaça)

```lua
{
    type = 'smoke',
    smoke = {
        mode = 'continuous',         -- continuous, burst, ground
        density = 1.0,               -- Densidade (0.1 a 3.0)
        height = 2.0,                -- Altura (0.5 a 5.0)
        syncWithMusic = true         -- Sincronizar com batida
    }
}
```

### Lasers

```lua
{
    type = 'lasers',
    lasers = {
        color = '#00ff00',           -- Cor em hexadecimal
        pattern = 'beams',           -- beams, grid, spiral, random
        count = 4,                   -- Número de lasers (1 a 16)
        speed = 1.0,                 -- Velocidade (0.1 a 5.0)
        syncWithMusic = true         -- Sincronizar com batida
    }
}
```

## 🔧 Sincronização com Música

Todos os efeitos suportam sincronização com a música:

```lua
syncWithMusic = true
```

Quando ativado:
- ✅ Efeitos pulsam no beat
- ✅ Intensidade aumenta 3-4x no beat
- ✅ Cores podem mudar no beat (alguns modos)
- ✅ Velocidade aumenta no beat

## 📊 Performance

### Otimizações Implementadas

1. **Wait Inteligente**: Efeitos pausam quando música não está tocando
2. **Frame Skip**: Alguns efeitos pulam frames quando não visíveis
3. **LOD**: Efeitos distantes usam menos recursos (a implementar)

### Dicas de Performance

- Use `intensity` menor para melhor FPS
- Evite muitos efeitos simultâneos
- Use `syncWithMusic = false` se não precisar

## 🐛 Debug

### Logs de Efeitos

Cada efeito imprime logs no console:

```
[DJ Light] Starting VOLUMETRIC STAGE LIGHTS
[DJ Light] Effect ID: effect_123
[DJ Light] Config - Mode: movinghead, Color: RGB(0,255,255)
```

### Verificar se Efeito Está Ativo

```lua
-- No console F8
print(json.encode(activeEffects))
```

## 📝 Criar Novo Efeito

### Passo a Passo

1. **Crie novo arquivo** (ex: `effects_custom.lua`)

```lua
function StartCustomEffect(entity, effectId, config)
    print("[DJ Custom] Starting custom effect")
    
    Citizen.CreateThread(function()
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                
                -- Seu código aqui
                DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, 
                    255, 0, 0, 10.0, 20.0)
            end
            
            Wait(IsMusicPlayingInZone(entity) and 0 or 500)
        end
        
        print("[DJ Custom] Effect stopped")
    end)
end
```

2. **Adicione ao fxmanifest.lua**

```lua
client_scripts {
    'effects.lua',
    'effects_lasers.lua',
    'effects_custom.lua',  -- Seu novo arquivo
    'client.lua'
}
```

3. **Registre no client.lua**

Encontre a função `StartConfiguredEffect` e adicione:

```lua
elseif config.type == 'custom' then
    print("[DJ Effect] Starting CUSTOM effect")
    StartCustomEffect(entity, effectId, config.custom or {})
```

4. **Use no jogo**

```lua
effectConfig = {
    type = 'custom',
    custom = {
        -- Suas configurações
    }
}
```

## 🎓 Exemplos Práticos

### Exemplo 1: Luz Pulsante Simples

```lua
function StartSimplePulseEffect(entity, effectId, config)
    Citizen.CreateThread(function()
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local pulse = (math.sin(GetGameTimer() / 500) + 1) / 2
                
                DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, 
                    255, 0, 0, 10.0, 20.0 * pulse)
            end
            Wait(0)
        end
    end)
end
```

### Exemplo 2: Círculo de Luzes

```lua
function StartCircleLightsEffect(entity, effectId, config)
    Citizen.CreateThread(function()
        while DoesEntityExist(entity) and activeEffects[entity] and activeEffects[entity].effects[effectId] do
            if IsMusicPlayingInZone(entity) then
                local coords = GetEntityCoords(entity)
                local time = GetGameTimer() / 1000
                
                for i = 1, 8 do
                    local angle = (i * 45) + (time * 30)
                    local rad = math.rad(angle)
                    local x = coords.x + math.cos(rad) * 5.0
                    local y = coords.y + math.sin(rad) * 5.0
                    
                    DrawLightWithRange(x, y, coords.z + 1.0, 
                        0, 255, 255, 5.0, 15.0)
                end
            end
            Wait(0)
        end
    end)
end
```

## 🚀 Próximos Passos

1. ✅ Modularizar Stage Lights e Smoke
2. ✅ Modularizar Lasers
3. ⏳ Modularizar Confetti e Bubbles
4. ⏳ Modularizar Pyro, CO2 e UV
5. ⏳ Criar sistema de presets
6. ⏳ Adicionar LOD (Level of Detail)
7. ⏳ Criar editor visual de efeitos

## 📞 Suporte

Se tiver dúvidas sobre como modificar ou criar efeitos:

1. Leia este README completo
2. Veja os exemplos nos arquivos `effects_*.lua`
3. Abra uma issue no GitHub
4. Entre no Discord

---

**Feito com ❤️ para facilitar a customização!**
