# 🏗️ Arquitetura Modular - Qbx_DJ System

**Data de Criação:** 05/12/2025  
**Versão:** 1.0.0  
**Autor:** llimbus

---

## 📋 Visão Geral

Este documento descreve a arquitetura modular completa do sistema DJ. Cada funcionalidade foi separada em módulos independentes para facilitar manutenção, customização e escalabilidade.

## 🎯 Objetivos da Modularização

1. **Separação de Responsabilidades** - Cada módulo tem uma função específica
2. **Facilidade de Manutenção** - Modificar um módulo não afeta os outros
3. **Reutilização de Código** - Funções compartilhadas em módulos core
4. **Escalabilidade** - Fácil adicionar novos recursos
5. **Documentação Clara** - Cada mudança documentada

## 📁 Estrutura de Arquivos

```
Qbx_DJ/
├── 📄 fxmanifest.lua                 # Manifesto principal
├── 📄 config.lua                     # Configurações gerais
│
├── 📁 core/                          # Módulos Core (carregados primeiro)
│   ├── core_shared.lua               # Variáveis e funções compartilhadas
│   ├── core_utils.lua                # Utilitários (conversões, cálculos)
│   └── core_state.lua                # Gerenciamento de estado global
│
├── 📁 modules/                       # Módulos de Funcionalidade
│   ├── module_audio.lua              # Sistema de áudio
│   ├── module_beat.lua               # Sistema de batidas/BPM
│   ├── module_zones.lua              # Gerenciamento de zonas
│   ├── module_props.lua              # Sistema de props
│   ├── module_placement.lua          # Colocação de props
│   ├── module_playlist.lua           # Sistema de playlists
│   └── module_ui.lua                 # Interface e NUI callbacks
│
├── 📁 effects/                       # Módulos de Efeitos Visuais
│   ├── effects_core.lua              # Core de efeitos
│   ├── effects_lights.lua            # Luzes de palco
│   ├── effects_lasers.lua            # Lasers
│   ├── effects_smoke.lua             # Fumaça
│   ├── effects_particles.lua         # Confetti, Bubbles
│   └── effects_pyro.lua              # Pyro, CO2, UV, Fireworks
│
├── 📁 target/                        # Sistema de Target
│   ├── target_core.lua               # Core do target system
│   ├── target_ox.lua                 # Integração ox_target
│   ├── target_qb.lua                 # Integração qb-target
│   └── target_fallback.lua           # Fallback (raycast)
│
├── 📁 server/                        # Módulos Server-Side
│   ├── server_main.lua               # Server principal
│   ├── server_sync.lua               # Sincronização
│   ├── server_props.lua              # Gerenciamento de props
│   └── server_zones.lua              # Gerenciamento de zonas
│
├── 📁 html/                          # Interface Web
│   ├── index.html
│   ├── style.css
│   └── script.js
│
└── 📁 docs/                          # Documentação
    ├── ARCHITECTURE.md               # Este arquivo
    ├── MODULAR_INTEGRATION.md        # Guia de integração
    ├── MODULARIZATION_SUMMARY.md     # Resumo da modularização
    ├── EFFECTS_README.md             # Documentação de efeitos
    ├── CORE_STATE_EXPLAINED.md       # Explicação do State Management
    └── FILE_ORGANIZATION_GUIDE.md    # Guia de organização
```

## 🔧 Módulos Core Implementados

### ✅ `core/core_shared.lua` - Variáveis Globais
- `DJSystem.*` - Namespace principal
- Variáveis de estado (MusicBeat, ActiveEffects, AudioZones, etc)
- Constantes do sistema
- Tipos de props e efeitos
- Modelos nativos

### ✅ `core/core_utils.lua` - Utilitários (30+ funções)
- Conversões de cor (HEX, RGB, HSV)
- Cálculos matemáticos
- Raycast
- Notificações
- Sistema de logs
- Validação
- Formatação
- Manipulação de tabelas e strings

### ✅ `core/core_state.lua` - State Management
- Gerenciamento de estado da música
- Gerenciamento de efeitos
- Gerenciamento de zonas
- Gerenciamento de props
- Gerenciamento de UI
- Gerenciamento de playlist
- Sistema de callbacks (7 tipos)
- Debug e estatísticas

## 📝 Convenções de Nomenclatura

### Variáveis Globais
- `DJSystem.*` - Sistema principal
- `DJUtils.*` - Utilitários
- `DJState.*` - Estado
- `DJAudio.*` - Áudio
- `DJBeat.*` - Beat
- `DJZones.*` - Zonas
- `DJProps.*` - Props
- `DJPlacement.*` - Colocação
- `DJPlaylist.*` - Playlist
- `DJUI.*` - Interface
- `DJEffects.*` - Efeitos
- `DJTarget.*` - Target
- `DJServer.*` - Server

### Eventos
- `dj:*` - Eventos do sistema
- `dj:client:*` - Eventos client-side
- `dj:server:*` - Eventos server-side

### Callbacks NUI
- `camelCase` - Ex: `musicBeat`, `startPlacement`

## 🔄 Fluxo de Carregamento

```
1. fxmanifest.lua
   ↓
2. config.lua
   ↓
3. core/core_shared.lua      (Variáveis globais)
   ↓
4. core/core_utils.lua        (Utilitários)
   ↓
5. core/core_state.lua        (Estado global)
   ↓
6. modules/*.lua              (Módulos funcionais)
   ↓
7. effects/effects_core.lua   (Core de efeitos)
   ↓
8. effects/*.lua              (Efeitos específicos)
   ↓
9. target/target_core.lua     (Core de target)
   ↓
10. target/*.lua              (Target específico)
```

## 📊 Dependências entre Módulos

```
core_shared.lua
    ↓
core_utils.lua
    ↓
core_state.lua
    ↓
    ├── module_audio.lua
    ├── module_beat.lua
    ├── module_zones.lua
    ├── module_props.lua
    ├── module_placement.lua
    ├── module_playlist.lua
    ├── module_ui.lua
    └── effects_core.lua
            ↓
            ├── effects_lights.lua
            ├── effects_lasers.lua
            ├── effects_smoke.lua
            ├── effects_particles.lua
            └── effects_pyro.lua
```

## 🔐 Segurança

- Validação de permissões em `Config.HasPermission()`
- Sanitização de inputs em `DJUtils.Sanitize()`
- Rate limiting em eventos server-side
- Validação de coordenadas e modelos

## 📈 Performance

- Lazy loading de módulos quando possível
- Cache de dados frequentes
- Throttling de updates
- LOD (Level of Detail) para efeitos distantes
- Culling de efeitos não visíveis

## 📝 Documentação de Mudanças

Toda mudança deve ser documentada em:
1. **CHANGELOG.md** - Histórico de versões
2. **Comentários no código** - Explicação inline
3. **Commit messages** - Mensagens descritivas
4. **Este arquivo** - Atualizar arquitetura se necessário

## 🎯 Status Atual

### ✅ Fase 1 - Core Modules: COMPLETA
- [x] core_shared.lua
- [x] core_utils.lua
- [x] core_state.lua

### ⏳ Fase 2 - Functional Modules: A IMPLEMENTAR
- [ ] module_audio.lua
- [ ] module_beat.lua
- [ ] module_zones.lua
- [ ] module_props.lua
- [ ] module_placement.lua
- [ ] module_playlist.lua
- [ ] module_ui.lua

### ⏳ Fase 3 - Effects Modules: PARCIAL
- [x] effects_core.lua
- [x] effects_lights.lua
- [x] effects_lasers.lua
- [ ] effects_smoke.lua
- [ ] effects_particles.lua
- [ ] effects_pyro.lua

---

**Última Atualização:** 05/12/2025  
**Versão do Documento:** 2.0  
**Status:** 🚧 Em Desenvolvimento Ativo
