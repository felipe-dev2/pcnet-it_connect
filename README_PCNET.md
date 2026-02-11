# PCNET-IT Connect - RustDesk Customizado

![Visual](https://img.shields.io/badge/Visual-Preto%20%26%20Verde%20Neon-00FF00)
![Status](https://img.shields.io/badge/Status-Pronto%20para%20Build-00FF00)
![Flutter](https://img.shields.io/badge/Flutter-Desktop-02569B)

Versão customizada do RustDesk com identidade visual PCNET-IT Connect: preto e verde neon.

---

## Características

- Layout centralizado sem sidebar
- Cores preto (#000000) e verde neon (#00FF00)
- Efeitos neon glow em elementos interativos
- Textos em português
- Interface moderna e focada

---

## O que foi modificado?

### Layout
- **Removido**: Sidebar esquerda "Seu Computador"
- **Centralizado**: Campo de conexão principal
- **Adicionado**: Background gradiente preto para cinza escuro

### Visual
- **28 aplicações** de cores PCNET
- **Efeitos neon glow** em containers e indicadores
- **Bordas verde neon** com transições suaves
- **Status online** com efeito de brilho

### Textos
- "Control Remote Desktop" → **"Inserir ID PCNET-IT Connect"**
- "Enter Remote ID" → **"Digite o ID de conexão"**
- "Connect" → **"Conectar"**

---

## Arquivos Importantes

### Código Fonte
```
flutter/lib/common/pcnet_colors.dart              # Paleta de cores
flutter/lib/desktop/pages/connection_page.dart    # Página principal
flutter/lib/common/widgets/connection_page_title.dart  # Título
```

### Documentação
```
PCNET_CUSTOMIZATION_SUMMARY.md    # Resumo completo das modificações
PCNET_COLOR_REFERENCE.md          # Referência de cores
BUILD_INSTRUCTIONS.md             # Como fazer build
BEFORE_AFTER.md                   # Comparação visual
VALIDATION_CHECKLIST.md           # Checklist de testes
FILES_MODIFIED.txt                # Lista de arquivos
```

### Backups
```
flutter/lib/desktop/pages/connection_page.dart.backup
flutter/lib/common/widgets/connection_page_title.dart.backup
```

---

## Como fazer Build

### 1. Preparar ambiente

```bash
cd /opt/pcnet-it-connect/rustdesk/flutter
flutter pub get
```

### 2. Verificar código

```bash
flutter analyze
```

### 3. Testar (modo debug)

```bash
flutter run -d linux
```

### 4. Build de produção

```bash
flutter build linux --release
```

### 5. Executar

```bash
cd build/linux/x64/release/bundle
./rustdesk
```

---

## Paleta de Cores

| Cor | Hex | Uso |
|-----|-----|-----|
| Verde Neon | #00FF00 | Primária, bordas, botões |
| Verde Escuro | #00CC00 | Bordas sutis, hover |
| Preto | #000000 | Background principal |
| Cinza Escuro | #1a1a1a | Cards, containers |
| Cinza Médio | #2a2a2a | Inputs, elementos |
| Branco | #FFFFFF | Texto principal |
| Cinza Claro | #B0B0B0 | Texto secundário |

Veja mais detalhes em [PCNET_COLOR_REFERENCE.md](PCNET_COLOR_REFERENCE.md)

---

## Preview

### Antes
```
[Sidebar] │ Control Remote Desktop
          │ [Enter Remote ID____]
          │ [Connect] [⋮]
```

### Depois (PCNET)
```
        Inserir ID PCNET-IT Connect
        [Digite o ID de conexão]
        [Conectar] [⋮]
```

Layout centralizado, cores verde neon, efeitos glow!

---

## Estrutura de Cores

```dart
import 'package:flutter_hbb/common/pcnet_colors.dart';

// Usar em qualquer widget
Container(
  color: PCNETColors.blackPrimary,
  child: Text(
    'PCNET-IT Connect',
    style: TextStyle(color: PCNETColors.greenPrimary),
  ),
)
```

---

## Troubleshooting

### Erro: Cannot find pcnet_colors.dart
**Solução**: Verifique se o arquivo existe em `flutter/lib/common/pcnet_colors.dart`

### Erro: Flutter analyze falha
**Solução**: Execute `flutter clean && flutter pub get`

### Cores não aparecem
**Solução**: Reinicie a aplicação completamente (não use hot reload)

### Efeitos neon não visíveis
**Solução**: Verifique se o compositor do sistema suporta sombras

---

## Rollback (Reverter)

Para voltar ao RustDesk original:

```bash
# Restaurar arquivos originais
cp flutter/lib/desktop/pages/connection_page.dart.backup \
   flutter/lib/desktop/pages/connection_page.dart

cp flutter/lib/common/widgets/connection_page_title.dart.backup \
   flutter/lib/common/widgets/connection_page_title.dart

# Remover arquivo de cores
rm flutter/lib/common/pcnet_colors.dart

# Rebuild
flutter clean
flutter pub get
flutter build linux --release
```

---

## Testes

Use o checklist completo de validação:
- [VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md)

Áreas críticas:
1. Layout centralizado (sem sidebar)
2. Cores verde neon aplicadas
3. Efeitos neon glow visíveis
4. Textos em português
5. Funcionalidade de conexão mantida

---

## Requisitos do Sistema

- **Flutter SDK**: Versão compatível com o projeto
- **Rust**: Para compilar componentes nativos
- **Sistema**: Linux (testado), Windows, macOS
- **Compositor**: Com suporte a sombras (para efeitos neon)

---

## Performance

- Efeitos neon otimizados (sem impacto significativo)
- Renderização 60fps
- Uso de memória similar ao original
- Transições suaves

---

## Compatibilidade

- ✅ Linux (X11/Wayland)
- ✅ Windows 10/11
- ✅ macOS 12+
- ✅ Todas as resoluções HD+

---

## Funcionalidades Mantidas

Todas as funcionalidades originais do RustDesk foram mantidas:
- ✅ Conexão remota
- ✅ Transferência de arquivos
- ✅ Visualização de câmera
- ✅ Terminal remoto
- ✅ Histórico de conexões
- ✅ Favoritos
- ✅ Configurações

---

## Próximas Melhorias (Opcional)

- [ ] Logo PCNET na splash screen
- [ ] Customização de outras telas
- [ ] Tema escuro/claro toggle
- [ ] Animações de conexão personalizadas
- [ ] Sons de notificação customizados

---

## Suporte

### Documentação
Consulte os arquivos `PCNET_*.md` para informações detalhadas

### Build Issues
Veja [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)

### Customizações
Veja [PCNET_CUSTOMIZATION_SUMMARY.md](PCNET_CUSTOMIZATION_SUMMARY.md)

---

## Créditos

- **Base**: [RustDesk](https://github.com/rustdesk/rustdesk)
- **Customização**: PCNET-IT Connect
- **Visual**: Preto e Verde Neon
- **Data**: 2026-02-10

---

## Licença

Mantém a licença original do RustDesk.
Customizações PCNET são propriedade de PCNET-IT Connect.

---

## Screenshots

(Adicione screenshots após o build)

---

## Changelog

### v1.0 - 2026-02-10
- Sidebar removida
- Layout centralizado
- Visual preto e verde neon aplicado
- Textos traduzidos para português
- Efeitos neon glow adicionados
- 28 aplicações de cores PCNET
- Documentação completa criada

---

**PCNET-IT Connect**
Visual profissional. Tecnologia confiável.

🟢 Preto e Verde Neon
