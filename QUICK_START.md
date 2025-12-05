# ⚡ Quick Start - FiveM DJ System

Guia rápido para começar a usar o DJ System em 5 minutos!

## 🚀 Instalação Rápida

```bash
# 1. Clone o repositório
cd resources/
git clone https://github.com/llimbus/Qbx_DJ.git

# 2. Adicione ao server.cfg
echo "ensure Qbx_DJ" >> server.cfg

# 3. Reinicie o servidor
restart Qbx_DJ
```

## 🎮 Primeiros Passos

### 1. Abrir Console DJ
```
/dj
```
ou
```
F5 (se hotkeys habilitadas)
```

### 2. Tocar Música
1. Cole uma URL no campo "YouTube or MP3 URL"
2. Clique em **Play** (▶️)
3. Ajuste o volume com o slider

### 3. Criar Playlist
1. Pressione `F6` para abrir Stage Builder
2. Clique na tab **PLAYLIST**
3. Cole URLs e clique em **Adicionar**
4. Clique em **Play** (▶️) na música desejada

### 4. Colocar Props
1. Pressione `F6` para abrir Stage Builder
2. Clique na tab **PROPS**
3. Selecione um prop (ex: Speaker)
4. Use setas do teclado para posicionar
5. Pressione **Enter** para confirmar

### 5. Configurar Efeitos
1. Clique com botão direito no prop
2. Selecione **Manage Effects**
3. Clique em **Adicionar Efeito**
4. Configure cor, intensidade, padrão
5. Marque **Sync with Music** para sincronizar
6. Clique em **Confirm**

## 🎛️ Controles Básicos

### Console DJ
- **Play** - Tocar música
- **Pause** - Pausar música
- **Stop** - Parar música
- **Volume** - Ajustar volume (0-100%)
- **EQ** - Equalizar (Low/Mid/High)
- **Crossfader** - Mixar entre Deck A e B
- **BPM** - Ajustar batidas por minuto (60-180)

### Playlist
- **▶️ Play** - Tocar música
- **⬆️ Mover** - Mover para cima
- **⬇️ Mover** - Mover para baixo
- **🗑️ Remover** - Deletar música
- **🔀 Shuffle** - Ordem aleatória
- **🔁 Repeat** - Loop infinito
- **💾 Salvar** - Exportar JSON
- **📂 Carregar** - Importar JSON

### Stage Builder
- **Setas** - Mover prop
- **Q/E** - Rotacionar
- **Enter** - Confirmar
- **Backspace** - Cancelar
- **Delete** - Remover último prop

## 📝 Comandos Úteis

```bash
/dj                 # Abrir console DJ
/djbuilder          # Abrir stage builder
/djbeatcheck        # Verificar sistema de batidas
/djbeatinfo         # Mostrar info de batidas
/djbeattest 128     # Testar com 128 BPM
/djfix              # Resetar UI (emergência)
```

## 🎯 Exemplos de URLs

### YouTube
```
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/dQw4w9WgXcQ
```

### Áudio Direto
```
https://example.com/music.mp3
https://example.com/track.ogg
https://example.com/audio.wav
```

## 🎨 Efeitos Disponíveis

1. **Stage Lights** - Luzes coloridas sincronizadas
2. **Laser Show** - Lasers com padrões
3. **Smoke Machine** - Fumaça contínua ou burst
4. **Confetti** - Confetes coloridos
5. **Bubbles** - Bolhas de sabão
6. **Pyrotechnics** - Chamas e fogos
7. **CO2 Jets** - Jatos de CO2
8. **UV Lights** - Luzes ultravioleta
9. **None** - Sem efeito

## 🔧 Configuração Rápida

### Mudar BPM Padrão
**config.lua:**
```lua
Config.DefaultBPM = 140
```

### Aumentar Distância do Áudio
**config.lua:**
```lua
Config.MaxAudioDistance = 150.0
```

### Habilitar Hotkeys
**config.lua:**
```lua
Config.EnableHotkeys = true
```

### Adicionar Zona DJ
**config.lua:**
```lua
Config.Zones = {
    {
        name = "Minha Balada",
        coords = vector3(100.0, -200.0, 30.0),
        radius = 50.0
    }
}
```

## 🐛 Problemas Comuns

### UI não abre
```bash
/djfix
restart Qbx_DJ
```

### Áudio não toca
1. Verifique se a URL é válida
2. Teste com outra URL
3. Verifique o console F8 para erros

### Props não aparecem
1. Alguns props podem não existir
2. Veja a lista de props alternativos no TODO.md
3. Verifique os logs do servidor

### Target não funciona
1. Certifique-se que ox_target ou qb-target está instalado
2. Verifique a ordem no server.cfg
3. Use o fallback (raycast nativo)

## 📚 Documentação Completa

- **README.md** - Documentação completa
- **INSTALLATION.md** - Guia de instalação detalhado
- **TODO.md** - Funcionalidades planejadas
- **CHANGELOG.md** - Histórico de versões
- **CONTRIBUTING.md** - Como contribuir

## 💡 Dicas

1. **Use Deck A para playlist** - Reprodução automática funciona no Deck A
2. **Ajuste BPM** - Sincronize com a música para melhores efeitos
3. **Salve playlists** - Exporte suas playlists favoritas
4. **Teste props** - Nem todos os props existem em todas as versões
5. **Use efeitos com moderação** - Muitos efeitos podem causar lag

## 🎉 Pronto!

Agora você está pronto para usar o DJ System! Divirta-se! 🎵

---

**Precisa de ajuda?**
- Discord: https://discord.gg/seu-servidor
- Issues: https://github.com/llimbus/Qbx_DJ/issues
