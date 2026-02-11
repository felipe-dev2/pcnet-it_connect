import 'package:flutter/material.dart';

/// PCNET-IT Connect Color Palette
/// Visual profissional e limpo para branding PCNET
class PCNETColors {
  // Cores primárias - Verde PCNET (profissional, não neon)
  static const Color greenPrimary = Color(0xFF2ECC71);
  static const Color greenDark = Color(0xFF27AE60);
  static const Color greenLight = Color(0xFF55D98D);
  static const Color greenAccent = Color(0xFF00CC00);

  // Cores de fundo
  static const Color blackPrimary = Color(0xFF1B1B1F);
  static const Color grayDark = Color(0xFF2B2B30);
  static const Color grayMedium = Color(0xFF35353A);
  static const Color grayLight = Color(0xFF45454A);
  static const Color surfaceColor = Color(0xFF232328);

  // Cores de texto
  static const Color textPrimary = Color(0xFFE8E8EC);
  static const Color textSecondary = Color(0xFF9E9EA6);
  static const Color textGreen = Color(0xFF2ECC71);

  // Cores de status
  static const Color statusOnline = Color(0xFF2ECC71);
  static const Color statusOffline = Color(0xFF808080);
  static const Color statusConnecting = Color(0xFFF1C40F);
  static const Color statusError = Color(0xFFE74C3C);

  // Cores de UI
  static const Color borderColor = Color(0xFF3A3A40);
  static const Color borderDark = Color(0xFF2A2A30);
  static const Color dividerColor = Color(0xFF3A3A40);
  static const Color shadowColor = Color(0x20000000);

  // Cores de hover e interação
  static const Color hoverColor = Color(0xFF35353A);
  static const Color pressedColor = Color(0xFF2ECC71);
  static const Color focusColor = Color(0xFF2ECC71);

  // Gradientes
  static const LinearGradient greenGradient = LinearGradient(
    colors: [greenPrimary, greenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [blackPrimary, blackPrimary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras sutis (sem efeito neon)
  static BoxShadow get subtleShadow => BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  // Mantendo neonGlow como sombra sutil para compatibilidade
  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
}
