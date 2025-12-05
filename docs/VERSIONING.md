# 📌 Versionamento Semântico - Qbx_DJ System

**Data:** 05/12/2025  
**Versão Atual:** 1.0.0

---

## 📊 Histórico de Versões

### v1.0.0 - 05/12/2025 - MODULARIZAÇÃO COMPLETA
**Tipo:** MAJOR (Breaking Changes)

**Por que MAJOR?**
- ⚠️ **API mudou completamente** - Funções e variáveis renomeadas
- ⚠️ **Estrutura reorganizada** - Arquivos movidos para pastas (core/, effects/)
- ⚠️ **Migração obrigatória** - Código v0.1.0 NÃO funciona sem modificações
- ⚠️ **Incompatibilidade** - Breaking changes que quebram compatibilidade

**Mudanças:**
- Sistema modularizado (core/, modules/, effects/)
- State Management implementado
- 30+ funções utilitárias
- Sistema de callbacks
- Documentação completa

---

### v0.1.0 - Dezembro 2025 - SISTEMA DE PLAYLISTS
**Tipo:** MINOR (Nova funcionalidade)

**Por que MINOR?**
- ✨ **Nova feature** - Sistema de playlists completo
- ✅ **Compatível** - Não quebra código existente
- ✅ **Adicional** - Apenas adiciona funcionalidades

**Mudanças:**
- Sistema de playlists
- Shuffle e repeat
- Import/export JSON

---

## 📋 Regras de Versionamento

### Formato: `MAJOR.MINOR.PATCH`

#### MAJOR (1.0.0)
**Quando usar:**
- ⚠️ Mudanças que **QUEBRAM** compatibilidade
- ⚠️ API muda (funções renomeadas, removidas)
- ⚠️ Estrutura reorganizada
- ⚠️ Requer migração de código

**Exemplos:**
```
0.1.0 → 1.0.0  (modularização completa)
1.0.0 → 2.0.0  (remover suporte a framework antigo)
```

#### MINOR (0.1.0)
**Quando usar:**
- ✨ **Nova funcionalidade** compatível
- ✨ Adiciona features sem quebrar código
- ✨ Melhorias que não afetam API existente

**Exemplos:**
```
0.0.1 → 0.1.0  (adicionar sistema de playlists)
1.0.0 → 1.1.0  (adicionar hotkeys)
1.1.0 → 1.2.0  (adicionar efeitos de som)
```

#### PATCH (0.0.1)
**Quando usar:**
- 🐛 **Correção de bugs**
- 🐛 Fixes que não mudam funcionalidade
- 🐛 Melhorias de performance
- 🐛 Correções de documentação

**Exemplos:**
```
0.1.0 → 0.1.1  (corrigir bug de sincronização)
1.0.0 → 1.0.1  (corrigir memory leak)
1.2.0 → 1.2.1  (corrigir typo na UI)
```

---

## 🎯 Exemplos Práticos

### Exemplo 1: Adicionar Hotkeys
```
Versão Atual: 1.0.0
Mudança: Adicionar hotkeys (F5-F12)
Tipo: MINOR (nova feature, compatível)
Nova Versão: 1.1.0
```

### Exemplo 2: Corrigir Bug de Áudio
```
Versão Atual: 1.0.0
Mudança: Corrigir bug de sincronização
Tipo: PATCH (bug fix)
Nova Versão: 1.0.1
```

### Exemplo 3: Remover Suporte a Framework
```
Versão Atual: 1.0.0
Mudança: Remover suporte a ESX
Tipo: MAJOR (breaking change)
Nova Versão: 2.0.0
```

### Exemplo 4: Adicionar Efeitos de Som
```
Versão Atual: 1.1.0
Mudança: Adicionar airhorn, scratch, etc
Tipo: MINOR (nova feature)
Nova Versão: 1.2.0
```

---

## ✅ Checklist de Versionamento

Antes de incrementar versão, pergunte:

### É MAJOR?
- [ ] Quebra código existente?
- [ ] Requer migração?
- [ ] API mudou (funções renomeadas/removidas)?
- [ ] Estrutura reorganizada?

**Se SIM para qualquer:** Incrementar MAJOR

### É MINOR?
- [ ] Adiciona nova funcionalidade?
- [ ] Código antigo continua funcionando?
- [ ] Não quebra compatibilidade?

**Se SIM para todos:** Incrementar MINOR

### É PATCH?
- [ ] Apenas corrige bugs?
- [ ] Não adiciona features?
- [ ] Não quebra compatibilidade?

**Se SIM para todos:** Incrementar PATCH

---

## 📝 Como Atualizar Versão

### 1. Determine o Tipo
Use o checklist acima

### 2. Atualize os Arquivos

**fxmanifest.lua:**
```lua
version '1.0.0'
```

**core/core_shared.lua:**
```lua
DJSystem.Version = "1.0.0"
```

**CHANGELOG.md:**
```markdown
## [1.0.0] - 05/12/2025

### ⚠️ Breaking Changes (se MAJOR)
- Lista de mudanças que quebram compatibilidade

### ✨ Novidades (se MINOR)
- Lista de novas funcionalidades

### 🐛 Correções (se PATCH)
- Lista de bugs corrigidos
```

### 3. Commit e Tag

```bash
# Commit
git add .
git commit -m "chore: bump version to 1.0.0"

# Tag
git tag -a v1.0.0 -m "Release v1.0.0 - Modularização Completa"

# Push
git push origin main
git push origin v1.0.0
```

---

## 🚨 Erros Comuns

### ❌ ERRADO: Incrementar MINOR para breaking change
```
0.1.0 → 0.2.0  (modularização)
```
**Problema:** Quebra compatibilidade mas não incrementa MAJOR

### ✅ CORRETO: Incrementar MAJOR para breaking change
```
0.1.0 → 1.0.0  (modularização)
```

---

### ❌ ERRADO: Incrementar MAJOR para nova feature
```
1.0.0 → 2.0.0  (adicionar hotkeys)
```
**Problema:** Não quebra compatibilidade, deveria ser MINOR

### ✅ CORRETO: Incrementar MINOR para nova feature
```
1.0.0 → 1.1.0  (adicionar hotkeys)
```

---

### ❌ ERRADO: Incrementar MINOR para bug fix
```
1.0.0 → 1.1.0  (corrigir bug)
```
**Problema:** Não adiciona feature, deveria ser PATCH

### ✅ CORRETO: Incrementar PATCH para bug fix
```
1.0.0 → 1.0.1  (corrigir bug)
```

---

## 📞 Dúvidas?

Se não tiver certeza do tipo de versão:

1. **Leia o DEVELOPMENT.md** - Guia completo
2. **Use o checklist** - Responda as perguntas
3. **Na dúvida, incremente MAJOR** - Melhor ser conservador

---

**Versionamento correto = Código estável! 📌**
