/// Raios alinhados com SKILL §5. Quanto mais "ação", mais arredondado.
class AppRadius {
  AppRadius._();

  static const double sm = 6; // input rect (login)
  static const double md = 16; // chips, badges grandes
  static const double lg = 24; // input pill curto, card de inventory
  static const double xl = 32; // input pill longo, summary bento, card med
  static const double hero = 48; // hero banners, container do bottom nav (top)
  static const double pill =
      9999; // botão primário, avatares, ícones circulares

  // Apelidos legados (mantidos para não quebrar imports)
  static const double card = lg;
  static const double logo = 20;
}
