# 🎵 FiveM DJ System

Um sistema completo de DJ para servidores FiveM com suporte a múltiplas zonas, playlists, efeitos visuais sincronizados e muito mais!

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-green.svg)
![License](https://img.shields.io/badge/license-MIT-orange.svg)

## ✨ Características

### 🎛️ Sistema de DJ Profissional
- **2 Decks Independentes** - Mixe entre duas músicas
- **Suporte Multi-Formato** - YouTube, MP3, OGG, WAV, M4A, AAC, FLAC, OPUS, WebM
- **Controles Completos** - Play, Pause, Stop, Volume, EQ (Low/Mid/High)
- **Crossfader** - Transições suaves entre decks
- **BPM Control** - 60-180 BPM com sincronização de batidas

### 📋 Sistema de Playlists
- **Criar/Editar Playlists** - Nome customizável
- **Adicionar/Remover Músicas** - Interface drag-and-drop
- **Reordenar Tracks** - Mover para cima/baixo
- **Reprodução Automática** - Próxima música toca automaticamente
- **Modo Shuffle** - Ordem aleatória
- **Modo Repeat** - Loop infinito
- **Importar/Exportar** - Salvar playlists em JSON

### 🎪 Stage Builder
- **22 Props Nativos** - Sem necessidade de DLCs
- **DJ Equipment** - Mesa DJ, speakers, subwoofers
- **Stage Lights** - Spotlights, work lights, strobes, LED screens
- **Effects Equipment** - Smoke machines, CO2 jets, fog machines
- **Bar & Furniture** - Banquetas, mesas, decoração
- **Target System** - Suporte para ox_target, qb-target e fallback

### 🎨 Efeitos Visuais Avançados
- **9 Tipos de Efeitos** - Lights, Lasers, Smoke, Confetti, Bubbles, Pyro, CO2, UV, None
- **Configuração Detalhada** - Cor, intensidade, padrão, velocidade
- **Sincronização Musical** - Efeitos sincronizados com BPM
- **Múltiplos Efeitos** - Vários efeitos por prop
- **Gerenciador Visual** - Interface para editar/remover efeitos

### 🌍 Sistema Multi-Zona
- **Zonas Independentes** - Múltiplos DJs em locais diferentes
- **Áudio 3D** - Volume baseado em distância
- **Sincronização** - Todos os jogadores ouvem a mesma música
- **Sem Conflitos** - Cada zona opera independentemente

## 📦 Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/llimbus/Qbx_DJ.git
```

2. **Copie para sua pasta de resources**
```bash
cp -r Qbx_DJ [caminho-do-servidor]/resources/
```

3. **Adicione ao server.cfg**
```cfg
ensure Qbx_DJ
```

4. **Reinicie o servidor**
```bash
restart Qbx_DJ
```

## 🎮 Como Usar

### Comandos
- `/dj` - Abrir console DJ
- `/djbuilder` ou `F6` - Abrir Stage Builder
- `/djbeatcheck` - Verificar sistema de batidas
- `/djbeatinfo` - Mostrar info de batidas (10s)
- `/djbeattest [bpm]` - Testar sistema de batidas
- `/djfix` - Reset de UI focus (emergência)

### Console DJ
1. Insira uma URL (YouTube ou áudio direto) no Deck A ou B
2. Clique em **Play** para iniciar
3. Ajuste o **Volume** e **EQ** (Low/Mid/High)
4. Use o **Crossfader** para mixar entre decks
5. Ajuste o **BPM** para sincronizar efeitos

### Playlists
1. Abra o Stage Builder (`F6`)
2. Clique na tab **PLAYLIST**
3. Adicione URLs no campo de input
4. Use os botões:
   - ▶️ **Play** - Tocar música
   - ⬆️⬇️ **Mover** - Reordenar
   - 🗑️ **Remover** - Deletar
   - 🔀 **Shuffle** - Ordem aleatória
   - 🔁 **Repeat** - Loop infinito
   - 💾 **Salvar** - Exportar JSON
   - 📂 **Carregar** - Importar JSON

### Stage Builder
1. Abra o Stage Builder (`F6`)
2. Clique na tab **PROPS**
3. Selecione um prop (DJ Table, Speaker, etc)
4. Posicione com as setas do teclado
5. Confirme com **Enter**
6. Configure efeitos visuais

### Target System
- **Link Speaker** - Vincular speaker à zona DJ
- **Unlink Speaker** - Desvincular speaker
- **Manage Effects** - Gerenciar efeitos do prop
- **Remove Prop** - Remover prop

## 🛠️ Configuração

### Props Disponíveis (22 total)

#### DJ Equipment
- `prop_dj_deck_01` - Mesa DJ
- `prop_speaker_06` - Speaker Grande
- `prop_speaker_05` - Speaker Médio
- `prop_speaker_08` - Subwoofer

#### Stage Lights
- `prop_spot_01` - Spotlight
- `prop_worklight_03b` - Work Light
- `prop_worklight_04c` - Strobe Light
- `prop_tv_flat_01` - LED Screen

#### Effects Equipment
- `prop_air_bigradar` - Smoke Machine
- `prop_air_towbar_01` - CO2 Jet
- `prop_air_bigradar_l2` - Fog Machine

#### Bar & Furniture
- `prop_bar_stool_01` - Banqueta Bar
- `prop_bar_pump_06` - Torneira Cerveja
- `prop_table_03` - Mesa Redonda
- `prop_table_04` - Mesa Quadrada
- `prop_table_06` - Mesa VIP

#### Decoration
- `prop_barrier_work05` - Barreira
- `prop_beach_fire` - Fire Pit
- `prop_tv_flat_michael` - TV Grande
- `prop_neon_01` - Neon Light

### Target Systems Suportados
- **ox_target** (recomendado)
- **qb-target**
- **Fallback** (raycast nativo)

## 📋 Requisitos

- **FiveM Server** - Build 2802 ou superior
- **Framework** - Standalone (não requer ESX/QBCore)
- **Target System** - ox_target, qb-target ou nenhum (opcional)

## 🔧 Dependências

Nenhuma dependência externa necessária! O sistema é totalmente standalone.

### Bibliotecas Incluídas
- **Howler.js** - Reprodução de áudio
- **YouTube IFrame API** - Suporte para YouTube
- **Font Awesome** - Ícones

## 📊 Performance

- **Resmon Idle**: ~0.01ms
- **Resmon Ativo**: ~0.05ms
- **Uso de Memória**: ~15MB
- **Otimizado** para servidores com muitos jogadores

## 🐛 Problemas Conhecidos

- Alguns props podem não existir em todas as versões do GTA V
- Sincronização pode ter delay em servidores com lag alto
- YouTube pode ter restrições regionais em alguns vídeos

## 🗺️ Roadmap

### 🔥 Próxima Versão (v0.2.0) - Em Desenvolvimento

#### Melhorias nos Efeitos de Luzes e Visuais
Estamos trabalhando em uma grande atualização do sistema de efeitos visuais:

- **Efeitos de Luz Aprimorados**
  - Strobes sincronizados com batidas (flash no beat)
  - Lasers com múltiplos padrões (circular, linear, cruzado)
  - Spotlights com movimento automático
  - LED walls com animações customizáveis
  - Efeitos de neon e UV lights mais realistas

- **Novos Efeitos Atmosféricos**
  - Fog machine com densidade ajustável
  - Smoke bursts sincronizados com drops
  - Particle effects otimizados
  - Projeções de luz colorida nas paredes
  - Reflexos e iluminação ambiente dinâmica

- **Sincronização Musical Melhorada**
  - Detecção automática de drops e builds
  - Efeitos que respondem à intensidade da música
  - Padrões de luz baseados em frequências (graves, médios, agudos)
  - Transições suaves entre diferentes estados de iluminação

- **Performance Otimizada**
  - Sistema de LOD (Level of Detail) para efeitos distantes
  - Culling inteligente de efeitos não visíveis
  - Redução de lag em eventos com muitos jogadores
  - Cache de configurações de efeitos

### Alta Prioridade
- [ ] Sistema de efeitos visuais v2.0 (em desenvolvimento)
- [ ] Hotkeys (F5-F12) para controles rápidos
- [ ] Efeitos de som (airhorn, scratch, bass drop)
- [ ] Interface melhorada (discos giram, VU meters)
- [ ] Verificar todos os 22 props nativos

### Média Prioridade
- [ ] Controles avançados (pitch, cue points, loop)
- [ ] Sistema de eventos (agendar, convites)
- [ ] NPCs dançando (crowd simulation)
- [ ] Ambiente e decoração avançados

### Baixa Prioridade
- [ ] Sistema econômico (cobrar entrada, pagar DJs)
- [ ] Integrações (Spotify, SoundCloud, Discord)
- [ ] Modos especiais (automático, karaokê, battle)
- [ ] Comunidade (Discord, competições)

Veja o [ROADMAP.md](ROADMAP.md) e [TODO.md](TODO.md) completos para mais detalhes.

## 📝 Changelog

Veja [CHANGELOG.md](CHANGELOG.md) para histórico completo de versões.

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

## 👥 Autores

- **llimbus** - *Trabalho Inicial* - [llimbus](https://github.com/llimbus)

## 🙏 Agradecimentos

- Comunidade FiveM
- Howler.js
- YouTube IFrame API
- Font Awesome
- Todos os contribuidores

## 📞 Suporte

- **Discord**: [Seu Discord](https://discord.gg/seu-servidor)
- **Issues**: [GitHub Issues](https://github.com/llimbus/Qbx_DJ/issues)
- **Wiki**: [GitHub Wiki](https://github.com/llimbus/Qbx_DJ/wiki)

## 🌟 Screenshots

*Em breve...*

---

**Feito com ❤️ para a comunidade FiveM**
