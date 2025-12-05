# 🤝 Contribuindo para o FiveM DJ System

Obrigado por considerar contribuir para o FiveM DJ System! Este documento fornece diretrizes para contribuir com o projeto.

## 📋 Código de Conduta

- Seja respeitoso e inclusivo
- Aceite críticas construtivas
- Foque no que é melhor para a comunidade
- Mostre empatia com outros membros

## 🚀 Como Contribuir

### Reportando Bugs

1. **Verifique se o bug já foi reportado** nos [Issues](https://github.com/llimbus/Qbx_DJ/issues)
2. **Crie um novo issue** com:
   - Título claro e descritivo
   - Passos para reproduzir o bug
   - Comportamento esperado vs atual
   - Screenshots (se aplicável)
   - Versão do FiveM e do resource
   - Logs relevantes

### Sugerindo Melhorias

1. **Verifique se a sugestão já existe** nos Issues
2. **Crie um novo issue** com:
   - Título claro
   - Descrição detalhada da funcionalidade
   - Por que seria útil
   - Exemplos de uso (se aplicável)

### Pull Requests

1. **Fork o repositório**
2. **Crie uma branch** para sua feature:
   ```bash
   git checkout -b feature/MinhaFeature
   ```
3. **Faça suas alterações** seguindo o estilo de código
4. **Teste suas alterações** completamente
5. **Commit suas mudanças**:
   ```bash
   git commit -m "feat: adiciona nova funcionalidade X"
   ```
6. **Push para sua branch**:
   ```bash
   git push origin feature/MinhaFeature
   ```
7. **Abra um Pull Request**

## 📝 Estilo de Código

### Lua
- Use 4 espaços para indentação
- Nomes de variáveis em camelCase
- Nomes de funções em PascalCase
- Comentários em português ou inglês
- Use `local` sempre que possível

```lua
-- Bom
local function CalcularVolume(distancia)
    local volume = 1.0 - (distancia / 100.0)
    return math.max(0.0, math.min(1.0, volume))
end

-- Ruim
function calcular_volume(d)
    return 1-d/100
end
```

### JavaScript
- Use 4 espaços para indentação
- Use `const` e `let`, evite `var`
- Nomes em camelCase
- Use arrow functions quando apropriado
- Comentários em português ou inglês

```javascript
// Bom
const calculateVolume = (distance) => {
    const volume = 1.0 - (distance / 100.0);
    return Math.max(0.0, Math.min(1.0, volume));
};

// Ruim
var calcular_volume = function(d) {
    return 1-d/100;
}
```

### HTML/CSS
- Use 4 espaços para indentação
- Classes em kebab-case
- IDs em kebab-case
- Organize CSS por seções

```css
/* Bom */
.playlist-container {
    display: flex;
    flex-direction: column;
}

/* Ruim */
.playlistContainer{display:flex;flex-direction:column;}
```

## 🧪 Testes

- Teste todas as funcionalidades antes de submeter
- Teste em diferentes cenários (solo, multiplayer)
- Verifique performance (resmon)
- Teste compatibilidade com outros resources

## 📦 Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Mudanças na documentação
- `style:` - Formatação, ponto e vírgula, etc
- `refactor:` - Refatoração de código
- `perf:` - Melhorias de performance
- `test:` - Adição de testes
- `chore:` - Manutenção

Exemplos:
```bash
feat: adiciona sistema de hotkeys
fix: corrige bug de sincronização de áudio
docs: atualiza README com novos comandos
perf: otimiza loop de efeitos visuais
```

## 🎯 Prioridades

Veja [TODO.md](TODO.md) para funcionalidades planejadas.

### Alta Prioridade
- Hotkeys (F5-F12)
- Efeitos de som
- Melhorias de interface
- Testes de props

### Média Prioridade
- Controles avançados
- Mais efeitos visuais
- Sistema de eventos

### Baixa Prioridade
- Sistema econômico
- Integrações externas
- Modos especiais

## 📞 Dúvidas?

- Abra uma [Discussion](https://github.com/llimbus/Qbx_DJ/discussions)
- Entre no [Discord](https://discord.gg/seu-servidor)
- Envie um email para: seu-email@exemplo.com

## 🙏 Agradecimentos

Obrigado por contribuir! Cada contribuição, por menor que seja, é muito apreciada.

---

**Happy Coding! 🎵**
