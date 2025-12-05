# 🛠️ Guia de Desenvolvimento - Qbx_DJ

Este guia ajuda a manter o código estável e evitar quebras em futuras atualizações.

## 📋 Boas Práticas

### 1. Versionamento Semântico (SemVer)

Siga o padrão: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.0.0): Mudanças que quebram compatibilidade
- **MINOR** (0.1.0): Novas funcionalidades compatíveis
- **PATCH** (0.1.1): Correções de bugs

**Exemplos:**
```
0.1.0 → 0.1.1  (bug fix)
0.1.1 → 0.2.0  (nova feature)
0.9.0 → 1.0.0  (breaking change)
```

### 2. Branches e Workflow

```bash
main          # Código estável, sempre funcionando
├── develop   # Desenvolvimento ativo
├── feature/* # Novas funcionalidades
└── hotfix/*  # Correções urgentes
```

**Criar nova feature:**
```bash
git checkout -b feature/nome-da-feature
# Desenvolva...
git commit -m "feat: descrição"
git push origin feature/nome-da-feature
# Crie Pull Request para develop
```

**Hotfix urgente:**
```bash
git checkout -b hotfix/correcao-critica
# Corrija...
git commit -m "fix: descrição"
git push origin hotfix/correcao-critica
# Crie Pull Request para main
```

### 3. Commits Convencionais

Use prefixos padronizados:

```bash
feat:     # Nova funcionalidade
fix:      # Correção de bug
docs:     # Documentação
style:    # Formatação (sem mudança de código)
refactor: # Refatoração
perf:     # Melhoria de performance
test:     # Testes
chore:    # Manutenção
```

**Exemplos:**
```bash
git commit -m "feat: adicionar modo karaokê"
git commit -m "fix: corrigir sincronização de áudio"
git commit -m "docs: atualizar README com novos comandos"
git commit -m "perf: otimizar carregamento de props"
```

### 4. Testes Antes de Commitar

**Checklist:**
```bash
# 1. Testar no servidor
ensure Qbx_DJ
restart Qbx_DJ

# 2. Verificar console (F8)
# Procure por erros

# 3. Testar funcionalidades principais
/dj          # Console abre?
/djbuilder   # Stage Builder funciona?
# Tocar música
# Adicionar props
# Criar playlist

# 4. Verificar performance
resmon
# Deve estar < 0.10ms

# 5. Se tudo OK, commite
git add .
git commit -m "feat: sua mudança"
```

## 🔒 Proteção Contra Quebras

### 1. Nunca Modifique Diretamente a Main

```bash
# ❌ ERRADO
git checkout main
# editar arquivos...
git commit -m "mudança"
git push

# ✅ CORRETO
git checkout -b feature/minha-mudanca
# editar arquivos...
git commit -m "feat: minha mudança"
git push origin feature/minha-mudanca
# Criar Pull Request
```

### 2. Sempre Teste em Develop Primeiro

```bash
# Criar branch develop se não existir
git checkout -b develop

# Trabalhe em features
git checkout -b feature/nova-funcionalidade
# desenvolva...
git commit -m "feat: nova funcionalidade"

# Merge para develop
git checkout develop
git merge feature/nova-funcionalidade

# Teste extensivamente em develop
# Só depois merge para main
git checkout main
git merge develop
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin main --tags
```

### 3. Use Tags para Releases

```bash
# Sempre crie tag ao fazer release
git tag -a v0.2.0 -m "Release v0.2.0 - Descrição"
git push origin v0.2.0

# Se algo quebrar, volte para tag anterior
git checkout v0.1.0
```

### 4. Mantenha Backup de Versões Estáveis

```bash
# Antes de grandes mudanças
git tag -a v0.1.0-stable -m "Versão estável antes de mudanças"
git push origin v0.1.0-stable
```

## 📝 Atualização de Versão

### Passo a Passo Completo

**1. Atualizar fxmanifest.lua:**
```lua
version '0.2.0'
```

**2. Atualizar CHANGELOG.md:**
```markdown
## [0.2.0] - Janeiro 2026

### ✨ Novidades
- Nova funcionalidade X
- Melhoria Y

### 🐛 Correções
- Corrigido bug Z

### ⚠️ Breaking Changes
- Mudança que quebra compatibilidade (se houver)
```

**3. Atualizar README.md:**
```markdown
![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)
```

**4. Commitar mudanças:**
```bash
git add fxmanifest.lua CHANGELOG.md README.md
git commit -m "chore: bump version to 0.2.0"
```

**5. Criar tag:**
```bash
git tag -a v0.2.0 -m "Release v0.2.0 - Descrição das mudanças"
```

**6. Push:**
```bash
git push origin main
git push origin v0.2.0
```

**7. Criar Release no GitHub:**
```bash
gh release create v0.2.0 --title "v0.2.0 - Título" --notes "Descrição completa"
```

## 🔄 Estrutura de Arquivos Protegida

### Arquivos que NÃO devem ser modificados levemente:

```
client.lua       # Core do sistema
server.lua       # Lógica do servidor
html/script.js   # Lógica da UI
```

**Se precisar modificar:**
1. Crie backup
2. Teste extensivamente
3. Documente mudanças
4. Incremente versão MINOR ou MAJOR

### Arquivos seguros para modificar:

```
config.lua       # Configurações
README.md        # Documentação
CHANGELOG.md     # Histórico
TODO.md          # Planejamento
```

## 🧪 Testes Recomendados

### Antes de Cada Release:

**1. Testes Funcionais:**
- [ ] Console DJ abre (/dj)
- [ ] Stage Builder abre (/djbuilder)
- [ ] YouTube funciona
- [ ] Áudio direto funciona
- [ ] Playlists funcionam
- [ ] Props aparecem
- [ ] Efeitos visuais funcionam
- [ ] Target system funciona
- [ ] Multi-zona funciona

**2. Testes de Performance:**
- [ ] Resmon < 0.10ms
- [ ] Sem memory leaks
- [ ] Sem erros no console

**3. Testes de Compatibilidade:**
- [ ] Funciona sem ox_target
- [ ] Funciona sem qb-target
- [ ] Funciona standalone

## 📦 Dependências

### Atualizações de Bibliotecas:

**Howler.js:**
```html
<!-- Versão atual: 2.2.3 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/howler/2.2.3/howler.min.js"></script>

<!-- Antes de atualizar, teste em develop! -->
```

**YouTube IFrame API:**
```html
<!-- API do YouTube é mantida pelo Google -->
<!-- Geralmente não quebra, mas teste após atualizações -->
```

## 🚨 Rollback de Emergência

Se algo quebrar em produção:

```bash
# 1. Voltar para última versão estável
git checkout v0.1.0

# 2. Criar branch de hotfix
git checkout -b hotfix/emergency-fix

# 3. Corrigir problema
# editar arquivos...

# 4. Commitar
git commit -m "fix: correção emergencial"

# 5. Criar nova versão patch
git tag -a v0.1.1 -m "Hotfix v0.1.1"

# 6. Push
git push origin hotfix/emergency-fix
git push origin v0.1.1

# 7. Merge para main
git checkout main
git merge hotfix/emergency-fix
git push origin main
```

## 📊 Monitoramento

### Logs Importantes:

**Server Console:**
```lua
-- Adicione logs em pontos críticos
print("^2[Qbx_DJ]^7 Sistema iniciado")
print("^3[Qbx_DJ]^7 Aviso: " .. mensagem)
print("^1[Qbx_DJ]^7 Erro: " .. erro)
```

**Client Console (F8):**
```javascript
console.log('[Qbx_DJ] Info:', data);
console.warn('[Qbx_DJ] Aviso:', warning);
console.error('[Qbx_DJ] Erro:', error);
```

## 🔐 Segurança

### Nunca Commite:

```
❌ Senhas
❌ Tokens
❌ API Keys
❌ Dados pessoais
❌ IPs privados
```

### Use .gitignore:

```gitignore
config.local.lua
secrets.lua
*.env
.env.local
```

## 📞 Suporte

Se algo quebrar:

1. **Verifique Issues:** https://github.com/llimbus/Qbx_DJ/issues
2. **Crie Issue:** Descreva o problema detalhadamente
3. **Rollback:** Use versão anterior estável
4. **Aguarde Fix:** Monitore o repositório

---

**Seguindo este guia, seu código permanecerá estável e fácil de manter! 🚀**
