# 📦 Guia de Instalação - FiveM DJ System

Este guia fornece instruções detalhadas para instalar e configurar o FiveM DJ System.

## 📋 Requisitos

### Servidor
- **FiveM Server** - Build 2802 ou superior
- **txAdmin** (recomendado) ou servidor standalone
- **Espaço em disco**: ~20MB

### Opcional
- **ox_target** ou **qb-target** (para interações com props)
- **Framework**: ESX, QBCore ou Standalone (funciona com todos)

## 🚀 Instalação Básica

### Método 1: Download Direto

1. **Baixe a última versão**
   - Vá para [Releases](https://github.com/llimbus/Qbx_DJ/releases)
   - Baixe o arquivo `Qbx_DJ-v0.1.0.zip`

2. **Extraia os arquivos**
   ```bash
   unzip Qbx_DJ-v0.1.0.zip
   ```

3. **Copie para resources**
   ```bash
   cp -r Qbx_DJ [caminho-do-servidor]/resources/
   ```

4. **Adicione ao server.cfg**
   ```cfg
   ensure Qbx_DJ
   ```

5. **Reinicie o servidor**
   ```bash
   restart Qbx_DJ
   ```

### Método 2: Git Clone

1. **Clone o repositório**
   ```bash
   cd [caminho-do-servidor]/resources/
   git clone https://github.com/llimbus/Qbx_DJ.git
   ```

2. **Adicione ao server.cfg**
   ```cfg
   ensure Qbx_DJ
   ```

3. **Reinicie o servidor**
   ```bash
   restart Qbx_DJ
   ```

## ⚙️ Configuração

### 1. Permissões (Opcional)

Se você quiser restringir quem pode usar o DJ System:

**server.lua** (adicione no topo):
```lua
-- Lista de IDs permitidos
Config.AllowedPlayers = {
    'steam:110000xxxxxxxx',
    'license:xxxxxxxxxxxxxxxx'
}

-- Ou use ACE Permissions
-- add_ace group.admin "dj.use" allow
```

### 2. Target System

O sistema detecta automaticamente ox_target ou qb-target.

**Para ox_target:**
```lua
-- Já configurado automaticamente
```

**Para qb-target:**
```lua
-- Já configurado automaticamente
```

**Sem target system:**
```lua
-- Usa raycast nativo (fallback)
```

### 3. Zonas DJ (Opcional)

Você pode pré-configurar zonas DJ no mapa:

**server.lua**:
```lua
-- Adicione zonas pré-configuradas
Config.Zones = {
    {
        name = "Vanilla Unicorn",
        coords = vector3(120.0, -1280.0, 29.0),
        radius = 50.0
    },
    {
        name = "Bahama Mamas",
        coords = vector3(-1387.0, -618.0, 30.0),
        radius = 50.0
    }
}
```

### 4. Props Customizados (Opcional)

Adicione seus próprios props:

**html/index.html**:
```html
<div class="grid-item" data-prop="seu_prop_customizado">
    <i class="fa-solid fa-music"></i>
    <span>Seu Prop</span>
</div>
```

**client.lua**:
```lua
-- Adicione à lista de speakers ou effects
local speakerModels = {
    'prop_speaker_06',
    'seu_prop_customizado'
}
```

## 🧪 Testando a Instalação

1. **Entre no servidor**
2. **Digite `/dj`** - Deve abrir o console DJ
3. **Digite `/djbuilder`** ou pressione **F6** - Deve abrir o Stage Builder
4. **Adicione uma URL** no Deck A
5. **Clique em Play** - A música deve tocar

Se tudo funcionar, a instalação está completa! 🎉

## 🔧 Solução de Problemas

### Problema: Resource não inicia

**Solução:**
```bash
# Verifique os logs
# No console do servidor, procure por erros

# Verifique se o resource está na pasta correta
ls resources/Qbx_DJ/

# Verifique o fxmanifest.lua
cat resources/Qbx_DJ/fxmanifest.lua
```

### Problema: UI não abre

**Solução:**
```lua
-- Verifique se NUI está habilitado
-- No F8 console:
resmon

-- Reinicie o resource
restart Qbx_DJ

-- Use o comando de fix
/djfix
```

### Problema: Áudio não toca

**Solução:**
1. Verifique se a URL é válida
2. Teste com uma URL diferente
3. Verifique se o YouTube não está bloqueado
4. Tente usar um link direto de MP3

### Problema: Props não aparecem

**Solução:**
```lua
-- Alguns props podem não existir em todas as versões
-- Verifique os logs para ver quais props falharam
-- Use props alternativos do TODO.md
```

### Problema: Target não funciona

**Solução:**
```lua
-- Verifique se ox_target ou qb-target está instalado
-- Verifique a ordem de start no server.cfg:
ensure ox_target
ensure Qbx_DJ

-- Ou use o fallback (raycast nativo)
```

## 📊 Performance

### Otimização Recomendada

**server.cfg**:
```cfg
# Aumente o limite de recursos se necessário
sv_maxclients 64

# Otimize o OneSync
onesync on
```

**Monitoramento**:
```bash
# Use resmon para monitorar performance
resmon

# O DJ System deve usar ~0.01ms idle e ~0.05ms ativo
```

## 🔄 Atualizando

### Método 1: Download Manual

1. Baixe a nova versão
2. Faça backup da pasta atual
3. Substitua os arquivos
4. Reinicie o resource

### Método 2: Git Pull

```bash
cd resources/Qbx_DJ/
git pull origin main
restart Qbx_DJ
```

## 🆘 Suporte

Se você ainda tiver problemas:

1. **Verifique os logs** do servidor e cliente (F8)
2. **Leia a documentação** completa no README.md
3. **Procure issues existentes** no GitHub
4. **Crie um novo issue** com detalhes completos
5. **Entre no Discord** para suporte em tempo real

## 📞 Links Úteis

- **GitHub**: https://github.com/llimbus/Qbx_DJ
- **Discord**: https://discord.gg/seu-servidor
- **Wiki**: https://github.com/llimbus/Qbx_DJ/wiki
- **Issues**: https://github.com/llimbus/Qbx_DJ/issues

---

**Instalação completa! Divirta-se! 🎵**
