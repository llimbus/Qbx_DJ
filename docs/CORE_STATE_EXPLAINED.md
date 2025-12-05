# 🎯 Core State - Explicação Detalhada

**Data de Criação:** 05/12/2025  
**Versão:** 2.0.0  
**Autor:** llimbus

---

## 📋 O que é o Core State?

O `core/core_state.lua` é o **gerenciador centralizado de estado** do sistema DJ. Ele controla e monitora todas as mudanças de estado do sistema de forma organizada e segura.

## 🤔 Por que usar State Management?

### ❌ Sem State Management (Antes)

```lua
-- Acesso direto às variáveis
musicBeat.bpm = 140
musicBeat.isPlaying = true

-- Problemas:
-- ❌ Sem validação
-- ❌ Sem callbacks
-- ❌ Difícil de debugar
-- ❌ Sem histórico
-- ❌ Código espalhado
```

### ✅ Com State Management (Agora)

```lua
-- Acesso através do State Manager
DJState.SetMusicBeat(140, 0, true)

-- Benefícios:
-- ✅ Validação automática (BPM entre 60-180)
-- ✅ Callbacks quando muda
-- ✅ Logs automáticos
-- ✅ Histórico de mudanças
-- ✅ Código centralizado
```

---

## 🎵 Music Beat State

### Funções Disponíveis

#### `DJState.SetMusicBeat(bpm, beat, isPlaying)`
Atualiza o estado da música

```lua
-- Atualizar BPM e beat
DJState.SetMusicBeat(128, 0, true)

-- Apenas BPM
DJState.SetMusicBeat(140, nil, nil)

-- Apenas estado de playing
DJState.SetMusicBeat(nil, nil, false)
```

**Validações:**
- BPM é clampado entre 60-180
- Beat é normalizado (0-3)
- Timestamp é atualizado automaticamente

#### `DJState.GetMusicBeat()`
Obtém o estado atual da música

```lua
local beat = DJState.GetMusicBeat()
print(beat.bpm)        -- 128
print(beat.beat)       -- 0
print(beat.isPlaying)  -- true
print(beat.lastBeatTime) -- timestamp
```

#### `DJState.IsOnBeat()`
Verifica se está no beat

```lua
if DJState.IsOnBeat() then
    -- Fazer algo no beat
    print("♪ ON BEAT!")
end
```

#### `DJState.GetBeatPhase()`
Obtém a fase do beat (0.0 a 1.0)

```lua
local phase = DJState.GetBeatPhase()
-- 0.0 = início do beat
-- 0.5 = meio do beat
-- 1.0 = fim do beat
```

#### `DJState.SetMusicState(isPlaying, bpm)`
Atualiza apenas o estado de play/pause

```lua
-- Pausar música
DJState.SetMusicState(false)

-- Tocar música com novo BPM
DJState.SetMusicState(true, 140)
```

---

## 🎨 Effects State

### Funções Disponíveis

#### `DJState.AddEffect(entity, effectId, config)`
Adiciona um efeito a uma entidade

```lua
local success = DJState.AddEffect(entity, "effect_1", {
    type = 'lights',
    lights = {
        color = '#ff0000',
        mode = 'strobe',
        intensity = 5.0
    }
})

if success then
    print("Efeito adicionado!")
else
    print("Limite de efeitos atingido")
end
```

**Validações:**
- Verifica limite de efeitos por prop (5)
- Registra timestamp de criação
- Dispara callback

#### `DJState.RemoveEffect(entity, effectId)`
Remove um efeito

```lua
DJState.RemoveEffect(entity, "effect_1")
```

#### `DJState.UpdateEffect(entity, effectId, config)`
Atualiza configuração de um efeito

```lua
DJState.UpdateEffect(entity, "effect_1", {
    type = 'lights',
    lights = {
        color = '#00ff00',  -- Mudou a cor
        mode = 'strobe',
        intensity = 8.0     -- Aumentou intensidade
    }
})
```

#### `DJState.IsEffectActive(entity, effectId)`
Verifica se efeito está ativo

```lua
if DJState.IsEffectActive(entity, "effect_1") then
    print("Efeito está ativo")
end
```

#### `DJState.GetEffects(entity)`
Obtém todos os efeitos de uma entidade

```lua
local effects = DJState.GetEffects(entity)
for effectId, data in pairs(effects) do
    print(effectId, data.config.type)
end
```

#### `DJState.StopAllEffects(entity)`
Para todos os efeitos de uma entidade

```lua
DJState.StopAllEffects(entity)
```

---

## 🌍 Zones State

### Funções Disponíveis

#### `DJState.CreateZone(zoneId, djTable)`
Cria uma nova zona

```lua
DJState.CreateZone("zone_1", djTableEntity)
```

#### `DJState.DeleteZone(zoneId)`
Deleta uma zona

```lua
DJState.DeleteZone("zone_1")
```

#### `DJState.AddSpeaker(zoneId, speaker)`
Adiciona speaker à zona

```lua
DJState.AddSpeaker("zone_1", speakerEntity)
```

#### `DJState.RemoveSpeaker(zoneId, speaker)`
Remove speaker da zona

```lua
DJState.RemoveSpeaker("zone_1", speakerEntity)
```

#### `DJState.GetZone(zoneId)`
Obtém dados da zona

```lua
local zone = DJState.GetZone("zone_1")
print(zone.djTable)
print(#zone.speakers)
print(#zone.effects)
```

#### `DJState.IsMusicPlayingInZone(zoneId)`
Verifica se música está tocando na zona

```lua
if DJState.IsMusicPlayingInZone("zone_1") then
    print("Música tocando!")
end
```

---

## 🎪 Props State

### Funções Disponíveis

#### `DJState.RegisterProp(entity, model, coords, heading)`
Registra um prop spawnado

```lua
DJState.RegisterProp(entity, "prop_dj_deck_01", coords, 90.0)
```

#### `DJState.UnregisterProp(entity)`
Remove registro do prop

```lua
DJState.UnregisterProp(entity)
```

#### `DJState.GetProp(entity)`
Obtém dados do prop

```lua
local prop = DJState.GetProp(entity)
print(prop.model)
print(prop.coords)
print(prop.heading)
print(prop.spawnedAt)
```

---

## 🖥️ UI State

### Funções Disponíveis

#### `DJState.SetUIState(isOpen, mode, currentZone)`
Atualiza estado da UI

```lua
-- Abrir console DJ
DJState.SetUIState(true, 'dj', 'zone_1')

-- Abrir stage builder
DJState.SetUIState(true, 'builder', nil)

-- Fechar UI
DJState.SetUIState(false, nil, nil)
```

#### `DJState.GetUIState()`
Obtém estado da UI

```lua
local ui = DJState.GetUIState()
print(ui.isOpen)
print(ui.mode)
print(ui.currentZone)
```

---

## 📋 Playlist State

### Funções Disponíveis

#### `DJState.SetPlaylist(playlist)`
Atualiza playlist

```lua
DJState.SetPlaylist({
    name = "My Playlist",
    tracks = {
        "https://youtube.com/watch?v=...",
        "https://example.com/music.mp3"
    },
    currentIndex = 0,
    shuffle = false,
    repeat = true
})
```

#### `DJState.GetPlaylist()`
Obtém playlist atual

```lua
local playlist = DJState.GetPlaylist()
print(playlist.name)
print(#playlist.tracks)
print(playlist.currentIndex)
```

---

## 🔔 Sistema de Callbacks

### O que são Callbacks?

Callbacks permitem que você **execute código quando o estado muda**.

### Tipos de Callbacks

- `musicBeat` - Quando beat muda
- `musicState` - Quando música toca/para
- `effect` - Quando efeito é adicionado/removido/atualizado
- `zone` - Quando zona é criada/modificada
- `prop` - Quando prop é spawnado/removido
- `ui` - Quando UI abre/fecha
- `playlist` - Quando playlist muda

### Como Usar

#### Registrar Callback

```lua
-- Callback quando beat muda
local callbackId = DJState.RegisterCallback('musicBeat', function(bpm, beat)
    print(string.format("Beat mudou! BPM: %d, Beat: %d", bpm, beat))
end)

-- Callback quando efeito é adicionado
DJState.RegisterCallback('effect', function(action, entity, effectId, config)
    if action == 'added' then
        print(string.format("Efeito adicionado: %s (Tipo: %s)", effectId, config.type))
    elseif action == 'removed' then
        print(string.format("Efeito removido: %s", effectId))
    end
end)

-- Callback quando UI abre/fecha
DJState.RegisterCallback('ui', function(action, mode, zone)
    print(string.format("UI %s: Mode=%s, Zone=%s", action, mode, zone))
end)
```

#### Remover Callback

```lua
-- Remover callback específico
DJState.UnregisterCallback('musicBeat', callbackId)
```

### Exemplo Prático

```lua
-- Sincronizar luzes com beat
DJState.RegisterCallback('musicBeat', function(bpm, beat)
    if beat == 0 then
        -- Flash nas luzes a cada 4 beats
        TriggerEvent('dj:flashLights')
    end
end)

-- Notificar quando efeito é adicionado
DJState.RegisterCallback('effect', function(action, entity, effectId, config)
    if action == 'added' then
        DJUtils.Notify(string.format("Efeito %s adicionado!", config.type), 'success')
    end
end)

-- Salvar playlist quando muda
DJState.RegisterCallback('playlist', function(playlist)
    -- Salvar no servidor
    TriggerServerEvent('dj:savePlaylist', playlist)
end)
```

---

## 📊 Debug e Estatísticas

### `DJState.GetStats()`
Obtém estatísticas do sistema

```lua
local stats = DJState.GetStats()
print(stats.zones)          -- Número de zonas
print(stats.props)          -- Número de props
print(stats.effects)        -- Número de efeitos
print(stats.musicPlaying)   -- Se música está tocando
print(stats.bpm)            -- BPM atual
print(stats.uiOpen)         -- Se UI está aberta
print(stats.playlistTracks) -- Número de tracks
```

### `DJState.PrintStats()`
Imprime estatísticas no console

```lua
DJState.PrintStats()

-- Output:
-- ========================================
-- [DJ State] System Statistics
-- ========================================
-- Zones: 2
-- Props: 15
-- Effects: 8
-- Music: Playing (BPM: 128)
-- UI: Open
-- Playlist: 10 tracks
-- ========================================
```

---

## 🎯 Vantagens do State Management

### 1. Validação Automática
```lua
-- BPM inválido é corrigido automaticamente
DJState.SetMusicBeat(999, 0, true)  -- Será clampado para 180
```

### 2. Logs Automáticos
```lua
-- Todas as mudanças são logadas
DJState.AddEffect(entity, "effect_1", config)
-- Output: [DJ INFO] Effect added: Entity=123, ID=effect_1, Type=lights
```

### 3. Callbacks
```lua
-- Reaja a mudanças de estado
DJState.RegisterCallback('musicState', function(isPlaying, bpm)
    if isPlaying then
        StartPartyMode()
    else
        StopPartyMode()
    end
end)
```

### 4. Debug Facilitado
```lua
-- Veja o estado completo do sistema
DJState.PrintStats()
```

### 5. Histórico
```lua
-- Cada item tem timestamp de criação
local prop = DJState.GetProp(entity)
print("Spawnado há:", GetGameTimer() - prop.spawnedAt, "ms")
```

---

## 🔧 Migração do Código Antigo

### Antes (Acesso Direto)
```lua
musicBeat.bpm = 140
musicBeat.isPlaying = true

activeEffects[entity] = { effects = {} }
activeEffects[entity].effects[effectId] = { config = config }

audioZones[zoneId] = { djTable = entity, speakers = {} }
```

### Depois (State Manager)
```lua
DJState.SetMusicBeat(140, nil, true)

DJState.AddEffect(entity, effectId, config)

DJState.CreateZone(zoneId, entity)
```

---

## 📝 Boas Práticas

### ✅ Faça
- Use sempre `DJState.*` para modificar estado
- Registre callbacks para reagir a mudanças
- Use `DJState.GetStats()` para debug
- Valide dados antes de passar para o State

### ❌ Não Faça
- Não modifique `DJSystem.*` diretamente
- Não crie seu próprio sistema de estado paralelo
- Não ignore erros retornados pelas funções
- Não registre callbacks infinitos (memory leak)

---

## 🎓 Exemplos Completos

### Exemplo 1: Sistema de Efeitos Sincronizados

```lua
-- Registrar callback para sincronizar efeitos com beat
DJState.RegisterCallback('musicBeat', function(bpm, beat)
    -- A cada 4 beats, mudar cor dos efeitos
    if beat == 0 then
        local hue = (GetGameTimer() / 100) % 360
        local r, g, b = DJUtils.HSVToRGB(hue, 1, 1)
        local color = DJUtils.RGBToHex(r, g, b)
        
        -- Atualizar todos os efeitos de luz
        for entity, data in pairs(DJSystem.ActiveEffects) do
            for effectId, effect in pairs(data.effects) do
                if effect.config.type == 'lights' then
                    effect.config.lights.color = color
                    DJState.UpdateEffect(entity, effectId, effect.config)
                end
            end
        end
    end
end)
```

### Exemplo 2: Auto-Save de Playlist

```lua
-- Salvar playlist automaticamente quando muda
DJState.RegisterCallback('playlist', function(playlist)
    -- Salvar localmente
    local json = json.encode(playlist)
    -- Salvar no servidor ou localStorage
    TriggerServerEvent('dj:savePlaylist', json)
    
    DJUtils.Notify("Playlist salva automaticamente!", 'success')
end)
```

### Exemplo 3: Monitor de Performance

```lua
-- Monitorar performance a cada 5 segundos
Citizen.CreateThread(function()
    while true do
        Wait(5000)
        
        local stats = DJState.GetStats()
        
        -- Alertar se muitos efeitos
        if stats.effects > 20 then
            DJUtils.Warn("Muitos efeitos ativos (%d), performance pode ser afetada", stats.effects)
        end
        
        -- Alertar se muitos props
        if stats.props > 40 then
            DJUtils.Warn("Muitos props spawnados (%d), considere remover alguns", stats.props)
        end
    end
end)
```

---

## 📞 Suporte

Se tiver dúvidas sobre o State Management:
1. Leia este documento completo
2. Veja os exemplos práticos
3. Use `DJState.PrintStats()` para debug
4. Abra uma issue no GitHub

---

**State Management implementado com sucesso! 🎉**
