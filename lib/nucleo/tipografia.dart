/// Escala de tamanhos de fonte do app. Use estes nomes em vez de números
/// soltos, para os textos do mesmo tipo terem o mesmo tamanho em todas as telas.
abstract final class Tipografia {
  /// Selos e rótulos bem pequenos (ex.: o selo do Open Finance).
  static const double minimo = 11;

  /// Textos de apoio: datas, categorias, descrições curtas.
  static const double legenda = 12;

  /// Texto padrão de leitura, botões de texto e campos.
  static const double corpo = 14;

  /// Nomes em destaque dentro de cards e botões principais.
  static const double destaque = 16;

  /// Títulos de blocos menores e valores em destaque.
  static const double subtitulo = 18;

  /// Títulos de etapas, folhas e seções.
  static const double tituloSecao = 22;

  /// Título de tela (Início, Extrato, CO2...).
  static const double titulo = 24;

  /// Números grandes de cards (kg de CO2, valores).
  static const double numero = 28;

  /// O número principal da tela inicial.
  static const double numeroGrande = 32;

  /// O nome CO2Bank na abertura.
  static const double marca = 34;

  /// O limite escolhido no cadastro.
  static const double numeroGigante = 52;
}
