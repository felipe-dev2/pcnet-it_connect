# PCNET-IT Connect - Referência de Cores

## Paleta de Cores Completa

### Cores Primárias - Verde Neon
```
greenPrimary  = #00FF00  // Verde neon brilhante
greenDark     = #00CC00  // Verde neon escuro
greenLight    = #33FF33  // Verde neon claro
greenNeon     = #39FF14  // Verde neon intenso
```

### Cores de Fundo - Preto e Cinzas
```
blackPrimary  = #000000  // Preto puro
grayDark      = #1a1a1a  // Cinza muito escuro
grayMedium    = #2a2a2a  // Cinza médio escuro
grayLight     = #3a3a3a  // Cinza claro escuro
```

### Cores de Texto
```
textPrimary   = #FFFFFF  // Branco puro
textSecondary = #B0B0B0  // Cinza claro
textGreen     = #00FF00  // Verde neon
```

### Cores de Status
```
statusOnline     = #00FF00  // Verde neon (online)
statusOffline    = #808080  // Cinza (offline)
statusConnecting = #FFFF00  // Amarelo (conectando)
statusError      = #FF0000  // Vermelho (erro)
```

### Cores de UI
```
borderColor    = #00FF00  // Verde neon para bordas
borderDark     = #00CC00  // Verde escuro para bordas
dividerColor   = #2a2a2a  // Cinza para divisores
shadowColor    = #000000  // Preto transparente (40%)
```

### Cores de Interação
```
hoverColor     = #00FF00  // Verde neon ao passar o mouse
pressedColor   = #00CC00  // Verde escuro ao clicar
focusColor     = #39FF14  // Verde neon intenso ao focar
```

---

## Aplicações das Cores

### Container Principal
- Background: Gradiente de blackPrimary (#000000) para grayDark (#1a1a1a)
- Cria profundidade visual

### Campo de Conexão (Card)
- Background: grayDark (#1a1a1a)
- Borda: borderColor (#00FF00) com 2px
- Sombra: Efeito neon glow verde

### TextField (Input)
- Background: grayMedium (#2a2a2a)
- Texto: textPrimary (#FFFFFF)
- Cursor: greenPrimary (#00FF00)
- Borda Normal: borderDark (#00CC00) 1px
- Borda Focada: greenPrimary (#00FF00) 2px
- Placeholder: textSecondary (#B0B0B0)

### Botão Conectar
- Background: greenPrimary (#00FF00)
- Texto: blackPrimary (#000000)
- Peso: Bold
- Sombra: Verde neon sutil

### Menu de Opções
- Background: grayMedium (#2a2a2a)
- Borda: borderDark (#00CC00) 1.5px
- Ícones: greenPrimary (#00FF00)

### Indicador de Status
- Online: statusOnline (#00FF00) com efeito neon glow
- Conectando: statusConnecting (#FFFF00)
- Erro: statusError (#FF0000)
- Offline: statusOffline (#808080)

### Autocomplete (Dropdown)
- Background: grayDark (#1a1a1a)
- Sombra: Verde neon com opacidade 0.3
- Loading: CircularProgressIndicator verde neon

### Divisores
- Cor: dividerColor (#2a2a2a)
- Espessura: 1px

---

## Efeitos Especiais

### Neon Glow (Brilho Neon)
```dart
BoxShadow(
  color: greenPrimary.withOpacity(0.6),
  blurRadius: 20,
  spreadRadius: 1,
)
BoxShadow(
  color: greenPrimary.withOpacity(0.3),
  blurRadius: 40,
  spreadRadius: 2,
)
```

### Neon Shadow (Sombra Neon)
```dart
BoxShadow(
  color: greenPrimary.withOpacity(0.5),
  blurRadius: 10,
  spreadRadius: 2,
)
```

---

## Gradientes

### Background Gradient
```dart
LinearGradient(
  colors: [blackPrimary, grayDark],  // #000000 → #1a1a1a
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```

### Green Gradient
```dart
LinearGradient(
  colors: [greenPrimary, greenDark],  // #00FF00 → #00CC00
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## Contraste e Acessibilidade

### Combinações de Alto Contraste
✅ **Texto branco (#FFFFFF) em fundo preto (#000000)**: Contraste 21:1
✅ **Texto verde neon (#00FF00) em fundo preto (#000000)**: Contraste 15.3:1
✅ **Texto preto (#000000) em botão verde (#00FF00)**: Contraste 15.3:1

### Combinações de Médio Contraste
⚠️ **Texto cinza (#B0B0B0) em fundo escuro (#1a1a1a)**: Contraste 8.2:1

---

## Uso Recomendado

### Para Elementos Principais
- Use **greenPrimary** (#00FF00) para ações primárias
- Use **blackPrimary** (#000000) para fundos principais
- Use **textPrimary** (#FFFFFF) para texto importante

### Para Elementos Secundários
- Use **borderDark** (#00CC00) para bordas sutis
- Use **grayMedium** (#2a2a2a) para fundos de inputs
- Use **textSecondary** (#B0B0B0) para texto secundário

### Para Feedback Visual
- Use **statusOnline** (#00FF00) + efeito neon para sucesso
- Use **statusError** (#FF0000) para erros
- Use **statusConnecting** (#FFFF00) para processos em andamento

---

## Exportação de Cores

### CSS
```css
:root {
  --pcnet-green-primary: #00FF00;
  --pcnet-green-dark: #00CC00;
  --pcnet-black-primary: #000000;
  --pcnet-gray-dark: #1a1a1a;
  --pcnet-gray-medium: #2a2a2a;
  --pcnet-text-primary: #FFFFFF;
  --pcnet-text-secondary: #B0B0B0;
}
```

### Dart (Flutter)
```dart
import 'package:flutter_hbb/common/pcnet_colors.dart';

// Usar diretamente
color: PCNETColors.greenPrimary,
backgroundColor: PCNETColors.blackPrimary,
```

---

**Paleta desenvolvida para PCNET-IT Connect**
Identidade visual: Preto e verde neon
