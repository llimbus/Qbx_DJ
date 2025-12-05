# 🔒 Configuração de Proteção de Branches

Para proteger as branches principais e seguir o workflow do DEVELOPMENT.md, configure as seguintes regras no GitHub:

## Configurar no GitHub

Acesse: https://github.com/llimbus/Qbx_DJ/settings/branches

## Branch: `main`

### Regras de Proteção:

1. **Require a pull request before merging** ✅
   - Require approvals: 1 (ou 0 se você trabalha sozinho)
   - Dismiss stale pull request approvals when new commits are pushed ✅

2. **Require status checks to pass before merging** ✅
   - Require branches to be up to date before merging ✅
   - Status checks: `version-check` (quando configurado)

3. **Require conversation resolution before merging** ✅

4. **Do not allow bypassing the above settings** ✅ (opcional)

### Resultado:
- ❌ Não pode fazer push direto para `main`
- ✅ Precisa criar Pull Request
- ✅ Precisa passar nos checks
- ✅ Mantém histórico limpo

## Branch: `develop`

### Regras de Proteção (mais flexíveis):

1. **Require a pull request before merging** ⚠️ (opcional)
   - Pode permitir push direto para testes rápidos

2. **Require status checks to pass before merging** ✅
   - Require branches to be up to date before merging ✅

### Resultado:
- ✅ Pode fazer push direto (para desenvolvimento rápido)
- ✅ Mas ainda recomendado usar feature branches
- ✅ Testes antes de merge para main

## Workflow Atual

```
main (protegida)
  ↑
  └── Pull Request (com review)
        ↑
      develop (semi-protegida)
        ↑
        └── feature/* (livre)
```

## Como Trabalhar Agora

### 1. Para Nova Feature:

```bash
# Certifique-se de estar em develop
git checkout develop
git pull origin develop

# Crie branch de feature
git checkout -b feature/nome-da-feature

# Desenvolva...
# Teste...

# Commit
git add .
git commit -m "feat: descrição da feature"

# Push
git push origin feature/nome-da-feature

# Crie Pull Request para develop
gh pr create --base develop --title "feat: nome da feature" --body "Descrição"
```

### 2. Para Bug Fix:

```bash
# Certifique-se de estar em develop
git checkout develop
git pull origin develop

# Crie branch de fix
git checkout -b fix/nome-do-bug

# Corrija...
# Teste...

# Commit
git add .
git commit -m "fix: descrição da correção"

# Push
git push origin fix/nome-do-bug

# Crie Pull Request para develop
gh pr create --base develop --title "fix: nome do bug" --body "Descrição"
```

### 3. Para Hotfix Urgente (produção):

```bash
# Crie branch direto da main
git checkout main
git pull origin main
git checkout -b hotfix/correcao-critica

# Corrija...
# Teste MUITO BEM...

# Commit
git add .
git commit -m "fix: correção crítica"

# Push
git push origin hotfix/correcao-critica

# Crie Pull Request para main
gh pr create --base main --title "hotfix: correção crítica" --body "Descrição"

# Depois merge também para develop
git checkout develop
git merge hotfix/correcao-critica
git push origin develop
```

### 4. Para Release (develop → main):

```bash
# Certifique-se de que develop está estável
git checkout develop
git pull origin develop

# Atualize versão
# Edite: fxmanifest.lua, CHANGELOG.md, README.md

# Commit de versão
git add fxmanifest.lua CHANGELOG.md README.md
git commit -m "chore: bump version to 0.2.0"
git push origin develop

# Crie Pull Request de develop para main
gh pr create --base main --title "Release v0.2.0" --body "Release notes aqui"

# Após merge, crie tag na main
git checkout main
git pull origin main
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0

# Crie release no GitHub
gh release create v0.2.0 --title "v0.2.0 - Título" --notes "Notas da release"
```

## Status Atual

- ✅ Branch `main` criada (produção)
- ✅ Branch `develop` criada (desenvolvimento)
- ✅ Você está em: `develop`
- ⚠️ Proteções precisam ser configuradas manualmente no GitHub

## Próximos Passos

1. Configure proteções no GitHub (link acima)
2. Sempre trabalhe em feature branches
3. Teste antes de fazer PR
4. Documente no CHANGELOG
5. Atualize versão quando necessário

---

**Agora você está seguindo as melhores práticas! 🚀**
