# Instruções de Build - PCNET-IT Connect RustDesk

## Pré-requisitos

Certifique-se de ter instalado:
- Flutter SDK (versão compatível com o projeto)
- Rust toolchain
- Dependências de desenvolvimento do RustDesk

## Passo 1: Verificar Estrutura

```bash
# Verificar arquivos criados
ls -la /opt/pcnet-it-connect/rustdesk/flutter/lib/common/pcnet_colors.dart
ls -la /opt/pcnet-it-connect/rustdesk/flutter/lib/desktop/pages/connection_page.dart
ls -la /opt/pcnet-it-connect/rustdesk/flutter/lib/common/widgets/connection_page_title.dart
```

## Passo 2: Instalar Dependências Flutter

```bash
cd /opt/pcnet-it-connect/rustdesk/flutter
flutter pub get
```

## Passo 3: Verificar Imports

Execute uma verificação de análise estática:

```bash
flutter analyze
```

Se houver erros de import, verifique se o arquivo `pcnet_colors.dart` está acessível.

## Passo 4: Build para Desktop

### Linux
```bash
cd /opt/pcnet-it-connect/rustdesk
flutter build linux --release
```

### Windows (se estiver em ambiente Windows)
```bash
cd /opt/pcnet-it-connect/rustdesk
flutter build windows --release
```

### macOS (se estiver em ambiente macOS)
```bash
cd /opt/pcnet-it-connect/rustdesk
flutter build macos --release
```

## Passo 5: Teste em Modo Debug

Antes do build final, teste em modo debug:

```bash
cd /opt/pcnet-it-connect/rustdesk/flutter
flutter run -d linux
```

ou especifique o device:

```bash
flutter devices  # listar dispositivos disponíveis
flutter run -d <device_id>
```

## Passo 6: Verificação Visual

Ao executar, verifique:

### Layout
- ✅ Campo de conexão está centralizado na tela
- ✅ Não há sidebar esquerda ("Seu Computador")
- ✅ Background com gradiente preto para cinza escuro
- ✅ Espaçamento adequado ao redor do campo de conexão

### Textos
- ✅ Título: "Inserir ID PCNET-IT Connect" (verde neon)
- ✅ Placeholder: "Digite o ID de conexão" (cinza)
- ✅ Botão: "Conectar" (texto preto em fundo verde neon)

### Cores
- ✅ Container do campo com borda verde neon e efeito glow
- ✅ TextField com fundo cinza médio e cursor verde neon
- ✅ Botão Conectar com fundo verde neon
- ✅ Ícones do menu em verde neon
- ✅ Indicador de status com cor verde neon quando online

### Efeitos
- ✅ Efeito neon glow ao redor do container principal
- ✅ Efeito glow no indicador de status quando online
- ✅ Transições suaves ao focar no campo de texto
- ✅ Borda muda de cor ao focar (verde escuro → verde neon)

## Passo 7: Build de Produção

Após validação visual:

```bash
cd /opt/pcnet-it-connect/rustdesk
# Build completo do RustDesk com customizações
./build.sh  # ou script de build específico do projeto
```

## Troubleshooting

### Erro: "Cannot find pcnet_colors.dart"

Verifique o caminho do import:
```dart
import '../../common/pcnet_colors.dart';
```

O caminho deve ser relativo ao arquivo que está importando.

### Erro: "Undefined name PCNETColors"

Certifique-se de que o import está presente no arquivo:
```dart
import 'package:flutter_hbb/common/pcnet_colors.dart';
// ou
import '../../common/pcnet_colors.dart';
```

### Erro de compilação Flutter

Limpe o cache e tente novamente:
```bash
flutter clean
flutter pub get
flutter build linux --release
```

### Problema com cores não aparecendo

Verifique se o hot reload está funcionando. Às vezes é necessário:
```bash
# Parar a aplicação (Ctrl+C)
# Executar novamente
flutter run -d linux
```

### Problema com efeito neon

Os efeitos de sombra podem não aparecer se:
1. O sistema não suporta sombras em widgets
2. O compositor do sistema está desabilitado
3. Está rodando em modo performance (algumas sombras são desabilitadas)

## Verificação de Build

Após o build, verifique o binário gerado:

### Linux
```bash
ls -lh /opt/pcnet-it-connect/rustdesk/build/linux/x64/release/bundle/
./rustdesk  # executar
```

### Windows
```bash
dir C:\path\to\rustdesk\build\windows\release\
rustdesk.exe  # executar
```

## Rollback (Reverter Modificações)

Se precisar reverter:

```bash
# Restaurar arquivos originais
cp /opt/pcnet-it-connect/rustdesk/flutter/lib/desktop/pages/connection_page.dart.backup \
   /opt/pcnet-it-connect/rustdesk/flutter/lib/desktop/pages/connection_page.dart

cp /opt/pcnet-it-connect/rustdesk/flutter/lib/common/widgets/connection_page_title.dart.backup \
   /opt/pcnet-it-connect/rustdesk/flutter/lib/common/widgets/connection_page_title.dart

# Remover arquivo de cores (opcional)
rm /opt/pcnet-it-connect/rustdesk/flutter/lib/common/pcnet_colors.dart

# Rebuild
cd /opt/pcnet-it-connect/rustdesk/flutter
flutter clean
flutter pub get
flutter build linux --release
```

## Próximos Passos

1. Testar conectividade com servidor PCNET-IT Connect
2. Verificar todas as funcionalidades (transferência de arquivos, câmera, terminal)
3. Testar em diferentes resoluções de tela
4. Criar instalador customizado com logo PCNET
5. Documentar processo de instalação para usuários finais

## Suporte Técnico

Para dúvidas ou problemas:
- Verifique logs: `flutter run --verbose`
- Consulte documentação RustDesk oficial
- Revise PCNET_CUSTOMIZATION_SUMMARY.md para detalhes das modificações

---

**Build PCNET-IT Connect v1.0**
Visual preto e verde neon
