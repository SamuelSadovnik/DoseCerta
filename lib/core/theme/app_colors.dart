import 'package:flutter/material.dart';

/// Tokens de cor do DoseCerta — alinhados com `docs/SKILL.md` §2.
///
/// Convenção: cores base ficam aqui; componentes consomem os apelidos
/// semânticos (`textPrimary`, `surface`, `success`, etc.).
class AppColors {
  AppColors._();

  // --- Vermelhos de marca ---
  static const Color red700 = Color(0xFFB02528); // brand
  static const Color red600 = Color(0xFFBA1A1A); // erro
  static const Color red500 = Color(0xFFD23E3E); // hero banner
  static const Color red400 = Color(0xFFD24040); // hover
  static const Color red200 = Color(0xFFFFDAD7); // tint suave
  static const Color redShadow = Color(0x33B02528); // glow do botão (alpha .20)

  // --- Marrom-escuro (texto) ---
  static const Color brown900 = Color(0xFF1A1C1C);
  static const Color brown700 = Color(0xFF5A413F);
  static const Color brown500 = Color(0xFF8E706E);
  static const Color brownTaupe = Color(0xFFE2BEBB);

  // --- Teal (sucesso) ---
  static const Color teal700 = Color(0xFF006859);
  static const Color teal100 = Color(0x1A006859); // 10% alpha

  // --- Cinzas e branco ---
  static const Color gray100 = Color(0xFFEEEEEE);
  static const Color gray50 = Color(0xFFF3F3F3);
  static const Color gray500 = Color(0xFFA1A1AA);
  static const Color gray600 = Color(0xFF737373);
  static const Color white = Color(0xFFFFFFFF);

  // --- Apelidos semânticos (preferir em componentes) ---
  static const Color primary = red700;
  static const Color primaryDark = red600;
  static const Color primaryLight = red200;
  static const Color primaryHero = red500;
  static const Color primaryShadow = redShadow;

  static const Color background = white;
  static const Color surface = gray100;
  static const Color surfaceAlt = gray50;

  static const Color textPrimary = brown900;
  static const Color textSecondary = brown700;
  static const Color textMuted = brown500;
  static const Color textPlaceholder = gray500;
  static const Color textInverse = white;

  static const Color success = teal700;
  static const Color successLight = teal100;
  static const Color warning = red600;
  static const Color error = red600;

  static const Color border = brownTaupe;
  static const Color divider = brownTaupe;
  static const Color iconInactive = gray600;
}
