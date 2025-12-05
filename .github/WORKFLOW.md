# 🔄 Workflow Obrigatório - Qbx_DJ

**SEMPRE SIGA ESTES PASSOS - SEM EXCEÇÕES**

## 📌 Regras Fundamentais

1. ❌ **NUNCA** faça commit direto na `main`
2. ❌ **NUNCA** faça push direto para `main`
3. ✅ **SEMPRE** trabalhe em branches de feature
4. ✅ **SEMPRE** teste antes de commitar
5. ✅ **SEMPRE** atualize CHANGELOG em mudanças significativas

## 🚀 Workflow Padrão

### 1️⃣ Iniciar Nova Feature/Fix

```bash
# Atualizar develop
git checkout develop
git pull origin develop

# Criar branch
git checkout -b feature/nome-descritivo
# ou
git checkout -b fix/nome-do-bug
```

### 2️⃣ Desenvolver

```bash
# Faça suas mudanças...
# Edite arquivos...
```

### 3️⃣ Testar (OBRIGATÓRIO)

```bash
# No servidor FiveM:
restart Qbx_DJ

# Checklist de testes:
# [ ] Console DJ abre (/dj)
# [ ] Stage Builder abre (/djbuilder)
# [ ] Música toca (YouTube e direto)
# [ ] Playlists funcionam
# [ ] Props aparecem
# [ ] Sem erros no F8
# [ ] Resmon < 0.10ms
```

### 4️⃣ Commitar

```bash
# Adicionar arquivos
git add .

# Commit com mensagem convencional
git commit -m "feat: descrição clara da mudança"
# ou
git commit -m "fix: descrição do bug corrigido"
# ou
git commit -m "docs: atualização de documentação"
```

**Prefixos válidos:**
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `style:` - Formatação
- `refactor:` - Refatoração
- `perf:` - Performance
- `test:` - Testes
- `chore:` - Manutenção

### 5️⃣ Push

```bash
git push origin feature/nome-descritivo
```

### 6️⃣ Pull Request

```bash
# Criar PR para develop
gh pr create --base develop --title "feat: título descritivo" --body "Descrição detalhada"

# Ou via GitHub web:
# https://github.com/llimbus/Qbx_DJ/compare/develop...feature/nome-descritivo
```

### 7️⃣ Merge e Limpeza

```bash
# Após aprovação e merge do PR
git checkout develop
git pull origin develop

# Deletar branch local
git branch -d feature/nome-descritivo

# Deletar branch remota
git push origin --delete feature/nome-descritivo
```

## 🎯 Release para Produção

### Quando develop está estável:

```bash
# 1. Atualizar versão
git checkout develop

# Editar arquivos:
# - fxmanifest.lua: version '0.x.0'
# - CHANGELOG.md: adicionar seção [0.x.0]
# - README.md: atualizar badge

# 2. Commit de versão
git add fxmanifest.lua CHANGELOG.md README.md
git commit -m "chore: bump version to 0.x.0"
git push origin develop

# 3. Criar PR de develop → main
gh pr create --base main --title "Release v0.x.0" --body "Release notes"

# 4. Após merge, criar tag
git checkout main
git pull origin main
git tag -a v0.x.0 -m "Release v0.x.0 - Descrição"
git push origin v0.x.0

# 5. Criar release no GitHub
gh release create v0.x.0 --title "v0.x.0 - Título" --notes "Notas completas"

# 6. Voltar para develop
git checkout develop
```

## 🚨 Hotfix Urgente (Produção Quebrada)

```bash
# 1. Branch direto da main
git checkout main
git pull origin main
git checkout -b hotfix/correcao-critica

# 2. Corrigir
# Edite arquivos...

# 3. Testar MUITO BEM
restart Qbx_DJ
# Teste tudo!

# 4. Commit
git add .
git commit -m "fix: correção crítica de [problema]"

# 5. Push
git push origin hotfix/correcao-critica

# 6. PR para main
gh pr create --base main --title "hotfix: correção crítica" --body "Descrição"

# 7. Após merge, atualizar develop também
git checkout develop
git merge hotfix/correcao-critica
git push origin develop

# 8. Criar tag patch
git checkout main
git pull origin main
git tag -a v0.x.1 -m "Hotfix v0.x.1"
git push origin v0.x.1
```

## 📊 Status Atual

```bash
# Ver branch atual
git branch

# Ver status
git status

# Ver histórico
git log --oneline -10

# Ver branches remotas
git branch -r
```

## ✅ Checklist Antes de Cada Commit

- [ ] Código testado no servidor
- [ ] Sem erros no console (F8)
- [ ] Performance OK (resmon < 0.10ms)
- [ ] Funcionalidades principais testadas
- [ ] Mensagem de commit clara e descritiva
- [ ] Arquivos corretos adicionados (git status)
- [ ] CHANGELOG atualizado (se mudança significativa)

## 🎓 Exemplos Práticos

### Exemplo 1: Adicionar Nova Feature

```bash
git checkout develop
git pull origin develop
git checkout -b feature/modo-karaoke

# Desenvolver modo karaokê...
# Testar...

git add .
git commit -m "feat: adicionar modo karaokê com letras sincronizadas"
git push origin feature/modo-karaoke
gh pr create --base develop --title "feat: Modo Karaokê"
```

### Exemplo 2: Corrigir Bug

```bash
git checkout develop
git pull origin develop
git checkout -b fix/playlist-shuffle

# Corrigir bug no shuffle...
# Testar...

git add .
git commit -m "fix: corrigir algoritmo de shuffle em playlists"
git push origin fix/playlist-shuffle
gh pr create --base develop --title "fix: Shuffle de Playlist"
```

### Exemplo 3: Atualizar Documentação

```bash
git checkout develop
git pull origin develop
git checkout -b docs/update-readme

# Atualizar README...

git add README.md
git commit -m "docs: adicionar exemplos de uso no README"
git push origin docs/update-readme
gh pr create --base develop --title "docs: Melhorar README"
```

## 🔐 Proteções Configuradas

- ✅ Branch `main` protegida (produção)
- ✅ Branch `develop` para desenvolvimento
- ✅ Feature branches para mudanças
- ✅ Pull Requests obrigatórios
- ✅ Testes antes de merge
- ✅ Versionamento semântico
- ✅ Tags para releases

## 📞 Comandos Rápidos

```bash
# Status rápido
git status

# Ver branch atual
git branch --show-current

# Atualizar develop
git checkout develop && git pull origin develop

# Criar feature
git checkout -b feature/nome

# Commit rápido
git add . && git commit -m "feat: descrição"

# Push
git push origin $(git branch --show-current)

# Voltar para develop
git checkout develop
```

---

**🎯 LEMBRE-SE: Sempre feature branch → develop → main**

**❌ NUNCA: Commit direto na main**

**✅ SEMPRE: Teste antes de commitar**
