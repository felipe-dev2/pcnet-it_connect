import 'package:flutter/material.dart';

/// PCNET-IT Connect Color Palette
/// Visual preto e verde neon para branding PCNET
class PCNETColors {
  // Cores primárias - Verde Neon
  static const Color greenPrimary = Color(0xFF00FF00);
  static const Color greenDark = Color(0xFF00CC00);
  static const Color greenLight = Color(0xFF33FF33);
  static const Color greenNeon = Color(0xFF39FF14);

  // Cores de fundo - Preto e cinzas
  static const Color blackPrimary = Color(0xFF000000);
  static const Color grayDark = Color(0xFF1a1a1a);
  static const Color grayMedium = Color(0xFF2a2a2a);
  static const Color grayLight = Color(0xFF3a3a3a);

  // Cores de texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textGreen = Color(0xFF00FF00);

  // Cores de status
  static const Color statusOnline = Color(0xFF00FF00);
  static const Color statusOffline = Color(0xFF808080);
  static const Color statusConnecting = Color(0xFFFFFF00);
  static const Color statusError = Color(0xFFFF0000);

  // Cores de UI
  static const Color borderColor = Color(0xFF00FF00);
  static const Color borderDark = Color(0xFF00CC00);
  static const Color dividerColor = Color(0xFF2a2a2a);
  static const Color shadowColor = Color(0x40000000);

  // Cores de hover e interação
  static const Color hoverColor = Color(0xFF00FF00);
  static const Color pressedColor = Color(0xFF00CC00);
  static const Color focusColor = Color(0xFF39FF14);

  // Gradientes
  static const LinearGradient greenGradient = LinearGradient(
    colors: [greenPrimary, greenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [blackPrimary, grayDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras com efeito neon
  static BoxShadow get neonShadow => BoxShadow(
    color: greenPrimary.withOpacity(0.5),
    blurRadius: 10,
    spreadRadius: 2,
  );

  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: greenPrimary.withOpacity(0.6),
      blurRadius: 20,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: greenPrimary.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 2,
    ),
  ];
}
